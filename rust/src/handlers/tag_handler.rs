use std::ops::Deref;

use sea_orm::{ColumnTrait, EntityTrait, QueryFilter, QueryOrder};
use uuid::Uuid;

use crate::database::entities::pending_mutation::MutationOperation;
use crate::database::entities::tag::{self, Entity as Tag};
use crate::database::entities::trip::{self, Entity as Trip};
use crate::database::entities::trip_tag::{self, Entity as TripTag};
use crate::database::entities::user_tag::{self, Entity as UserTag};
use crate::database::{repositories, Database};
use crate::commands::*;
use crate::handlers::Handler;
use crate::models::*;
use crate::sync;

pub struct TagHandler {
    db: Database,
}

impl Handler for TagHandler {
    fn create(db: Database) -> Self {
        Self { db }
    }
}

impl TagHandler {
    /// All tags visible to the caller: their own library (user_tags
    /// rows with deleted_at IS NULL) plus tags linked to any local
    /// trip via trip_tags. Anonymous callers fall back to "every
    /// local tag", since user_tags is per-account.
    pub async fn get_all_tags(&self) -> anyhow::Result<Vec<TagModel>> {
        let me = sync::session::current_user().await;
        let conn = self.db.deref();
        let candidates: Vec<tag::Model> = match me {
            Some(user_id) => {
                let library = UserTag::find()
                    .filter(user_tag::Column::UserId.eq(user_id))
                    .filter(user_tag::Column::DeletedAt.is_null())
                    .all(conn)
                    .await?
                    .into_iter()
                    .map(|ut| ut.tag_id);
                let linked = TripTag::find()
                    .filter(trip_tag::Column::DeletedAt.is_null())
                    .all(conn)
                    .await?
                    .into_iter()
                    .map(|tt| tt.tag_id);
                let mut ids: Vec<Uuid> = library.chain(linked).collect();
                ids.sort();
                ids.dedup();
                if ids.is_empty() {
                    Vec::new()
                } else {
                    Tag::find()
                        .filter(tag::Column::Id.is_in(ids))
                        .order_by_asc(tag::Column::Name)
                        .all(conn)
                        .await?
                }
            }
            None => Tag::find()
                .order_by_asc(tag::Column::Name)
                .all(conn)
                .await?,
        };
        Ok(candidates
            .into_iter()
            .map(|t| TagModel {
                id: t.id,
                name: t.name,
            })
            .collect())
    }

    pub async fn get_tag_by_id(&self, id: Uuid) -> anyhow::Result<Option<TagModel>> {
        let tag = repositories::tags::find_by_id(&self.db, id).await?;
        let tag_model = tag.map(|t| TagModel {
            id: t.id,
            name: t.name,
        });

        Ok(tag_model)
    }

    /// Create a tag. Tags are a global, append-only library — names
    /// share a content-addressed id (uuid v5 of the lowercased name),
    /// so two callers who type "Beach" end up with the same row both
    /// locally and on the server. When signed in we also record a
    /// `user_tags` row so this tag lands in the caller's library on
    /// every device, even when the global tag was first inserted by
    /// somebody else (the global insert is a duplicate and silently
    /// drops, but the user_tags push always succeeds).
    pub async fn create_tag(&self, command: CreateTag) -> anyhow::Result<TagModel> {
        let name = command.name.trim().to_string();
        if name.is_empty() {
            anyhow::bail!("Tag name can't be empty");
        }
        let tag = repositories::tags::create(&self.db, name).await?;
        enqueue_tag_row(&self.db, tag.id).await?;
        enqueue_user_tag(&self.db, tag.id).await?;
        Ok(TagModel {
            id: tag.id,
            name: tag.name,
        })
    }

    /// Rename a tag in the caller's library. Under the hood: tags are
    /// content-addressed and append-only, so we can't rename the
    /// global row. Instead we create the new tag (or reuse one that
    /// already exists), swap every trip_tags reference on trips the
    /// caller owns over to the new id, register the new tag in the
    /// caller's library, and soft-delete the old library row. Other
    /// devices pick up all of that via the normal sync path.
    ///
    /// If the new name normalises to the same id as the old, this
    /// is a no-op — content addressing means "Beach" and "beach"
    /// share a row already.
    pub async fn rename_tag(&self, old_tag_id: Uuid, new_name: String) -> anyhow::Result<TagModel> {
        let new_name = new_name.trim().to_string();
        if new_name.is_empty() {
            anyhow::bail!("Tag name can't be empty");
        }
        let new_id = sync::wire::tag_id_for_name(&new_name);
        if new_id == old_tag_id {
            // Same canonical id — just make sure the local row exists
            // under the requested name.
            let tag = repositories::tags::create(&self.db, new_name).await?;
            return Ok(TagModel {
                id: tag.id,
                name: tag.name,
            });
        }

        let new_tag = repositories::tags::create(&self.db, new_name).await?;
        enqueue_tag_row(&self.db, new_tag.id).await?;

        // Swap every owned-trip reference from the old id to the new.
        for trip_id in self.trips_owned_by_caller_with_tag(old_tag_id).await? {
            repositories::tags::add_tag_to_trip(&self.db, trip_id, new_id).await?;
            enqueue_trip_tag(&self.db, trip_id, new_id, MutationOperation::Insert).await?;
            repositories::tags::remove_tag_from_trip(&self.db, trip_id, old_tag_id).await?;
            enqueue_trip_tag(&self.db, trip_id, old_tag_id, MutationOperation::Delete).await?;
        }

        enqueue_user_tag(&self.db, new_id).await?;
        forget_user_tag(&self.db, old_tag_id).await?;

        Ok(TagModel {
            id: new_tag.id,
            name: new_tag.name,
        })
    }

    /// Remove a tag from the caller's library and from every trip
    /// they own. The global tag row stays (append-only). Other
    /// devices see the change via the user_tags / trip_tags pulls.
    pub async fn delete_tag(&self, tag_id: Uuid) -> anyhow::Result<()> {
        for trip_id in self.trips_owned_by_caller_with_tag(tag_id).await? {
            repositories::tags::remove_tag_from_trip(&self.db, trip_id, tag_id).await?;
            enqueue_trip_tag(&self.db, trip_id, tag_id, MutationOperation::Delete).await?;
        }
        forget_user_tag(&self.db, tag_id).await?;
        Ok(())
    }

    /// Trips the caller owns (anonymous mode: `owner_id IS NULL`)
    /// that currently carry the given tag. Used by the rename and
    /// delete paths so we don't touch tags on trips owned by other
    /// people.
    async fn trips_owned_by_caller_with_tag(
        &self,
        tag_id: Uuid,
    ) -> anyhow::Result<Vec<Uuid>> {
        let me_str = sync::session::current_user().await.map(|u| u.to_string());
        let conn = self.db.deref();
        let trip_ids: Vec<Uuid> = TripTag::find()
            .filter(trip_tag::Column::TagId.eq(tag_id))
            .filter(trip_tag::Column::DeletedAt.is_null())
            .all(conn)
            .await?
            .into_iter()
            .map(|tt| tt.trip_id)
            .collect();
        if trip_ids.is_empty() {
            return Ok(Vec::new());
        }
        let trips = Trip::find()
            .filter(trip::Column::Id.is_in(trip_ids))
            .all(conn)
            .await?;
        Ok(trips
            .into_iter()
            .filter(|t| t.owner_id == me_str)
            .map(|t| t.id)
            .collect())
    }

    pub async fn get_trip_tags(&self, trip_id: Uuid) -> anyhow::Result<Vec<TagModel>> {
        let tags = repositories::tags::find_by_trip_id(&self.db, trip_id).await?;
        let tag_models = tags.into_iter()
            .map(|tag| TagModel {
                id: tag.id,
                name: tag.name,
            })
            .collect();

        Ok(tag_models)
    }

    pub async fn add_tag_to_trip(&self, command: AddTagToTrip) -> anyhow::Result<()> {
        // Check if trip exists
        let trip = repositories::trips::find_by_id(&self.db, command.trip_id).await?;
        if trip.is_none() {
            return Err(anyhow::anyhow!("Trip not found"));
        }

        // Check if tag exists
        let tag = repositories::tags::find_by_id(&self.db, command.tag_id).await?;
        if tag.is_none() {
            return Err(anyhow::anyhow!("Tag not found"));
        }

        repositories::tags::add_tag_to_trip(&self.db, command.trip_id, command.tag_id).await?;
        enqueue_trip_tag(
            &self.db,
            command.trip_id,
            command.tag_id,
            MutationOperation::Insert,
        )
        .await?;
        // Assigning a tag pulls it into the caller's personal library
        // too — that way it appears in their picker on every device,
        // and stays around even after the tag is removed from this
        // trip.
        enqueue_user_tag(&self.db, command.tag_id).await?;
        Ok(())
    }

    pub async fn remove_tag_from_trip(&self, command: RemoveTagFromTrip) -> anyhow::Result<()> {
        enqueue_trip_tag(
            &self.db,
            command.trip_id,
            command.tag_id,
            MutationOperation::Delete,
        )
        .await?;
        repositories::tags::remove_tag_from_trip(&self.db, command.trip_id, command.tag_id).await?;
        Ok(())
    }

    pub async fn set_trip_tags(&self, command: SetTripTags) -> anyhow::Result<()> {
        // Check if trip exists
        let trip = repositories::trips::find_by_id(&self.db, command.trip_id).await?;
        if trip.is_none() {
            return Err(anyhow::anyhow!("Trip not found"));
        }

        // Verify all tags exist
        for tag_id in &command.tag_ids {
            let tag = repositories::tags::find_by_id(&self.db, *tag_id).await?;
            if tag.is_none() {
                return Err(anyhow::anyhow!("Tag with id {} not found", tag_id));
            }
        }

        // Snapshot the previous set so we can enqueue tombstones for the
        // tags that drop out before we hard-delete them locally.
        let previous = repositories::tags::find_by_trip_id(&self.db, command.trip_id).await?;
        for tag in previous {
            if !command.tag_ids.contains(&tag.id) {
                enqueue_trip_tag(&self.db, command.trip_id, tag.id, MutationOperation::Delete)
                    .await?;
            }
        }

        repositories::tags::clear_trip_tags(&self.db, command.trip_id).await?;

        for tag_id in command.tag_ids {
            repositories::tags::add_tag_to_trip(&self.db, command.trip_id, tag_id).await?;
            enqueue_trip_tag(&self.db, command.trip_id, tag_id, MutationOperation::Insert).await?;
            enqueue_user_tag(&self.db, tag_id).await?;
        }

        Ok(())
    }
}

/// Stamp a `user_tags(me, tag_id)` row locally and enqueue the push.
/// Idempotent — re-running for the same pair is a no-op. Skipped
/// entirely while anonymous; the row will be created when the
/// backfill flow runs after sign-in.
pub(crate) async fn enqueue_user_tag(db: &Database, tag_id: Uuid) -> anyhow::Result<()> {
    let Some(user_id) = sync::session::current_user().await else {
        return Ok(());
    };
    let created = repositories::user_tags::ensure(db, user_id, tag_id).await?;
    if !created {
        return Ok(());
    }
    let model = repositories::user_tags::find_by_id(db, user_id, tag_id)
        .await?
        .ok_or_else(|| anyhow::anyhow!("user_tag vanished mid-create"))?;
    let row = sync::wire::UserTagRow::from_model(&model);
    sync::push::enqueue_if_signed_in(
        db,
        "user_tags",
        tag_id,
        MutationOperation::Insert,
        &row,
    )
    .await
}

/// Forget a tag for the caller: hard-delete the local user_tags row
/// and enqueue a soft-delete on the server. Idempotent — no-op when
/// the user doesn't have the tag in their library or is anonymous.
pub(crate) async fn forget_user_tag(db: &Database, tag_id: Uuid) -> anyhow::Result<()> {
    let Some(user_id) = sync::session::current_user().await else {
        // Anonymous: there's no user_tags row to delete and nothing
        // to push.
        return Ok(());
    };
    if repositories::user_tags::find_by_id(db, user_id, tag_id)
        .await?
        .is_none()
    {
        return Ok(());
    }
    UserTag::delete_by_id((user_id, tag_id))
        .exec(db.deref())
        .await?;
    let payload = serde_json::json!({
        "user_id": user_id,
        "tag_id":  tag_id,
    });
    sync::push::enqueue_if_signed_in(
        db,
        "user_tags",
        tag_id,
        MutationOperation::Delete,
        &payload,
    )
    .await
}

/// Read the local tag row and enqueue an Insert mutation for it. Used
/// when a user creates a brand-new tag and we need to propagate the
/// global row to the server. No-op while anonymous.
pub(crate) async fn enqueue_tag_row(db: &Database, id: Uuid) -> anyhow::Result<()> {
    if sync::session::current_user().await.is_none() {
        return Ok(());
    }
    let Some(model) = repositories::tags::find_by_id(db, id).await? else {
        return Ok(());
    };
    let row = sync::wire::TagRow::from_model(&model);
    sync::push::enqueue_if_signed_in(db, "tags", id, MutationOperation::Insert, &row).await
}

/// Shared helper used by both `tag_handler` and (indirectly via the
/// trip-level tag setter) `trip_handler` to keep the queue in sync with
/// trip_tags changes. Composite keys aren't first-class in the mutation
/// table — we use the `tag_id` as the `entity_id` (it's only used for
/// dedup inside the queue) and stash both ids in the payload.
pub(crate) async fn enqueue_trip_tag(
    db: &Database,
    trip_id: Uuid,
    tag_id: Uuid,
    op: MutationOperation,
) -> anyhow::Result<()> {
    if sync::session::current_user().await.is_none() {
        return Ok(());
    }
    match op {
        MutationOperation::Delete => {
            let payload = serde_json::json!({
                "trip_id": trip_id,
                "tag_id": tag_id,
            });
            sync::push::enqueue_if_signed_in(db, "trip_tags", tag_id, op, &payload).await
        }
        _ => {
            let row = sync::wire::TripTagRow {
                trip_id,
                tag_id,
                updated_at: chrono::Utc::now(),
                deleted_at: None,
            };
            sync::push::enqueue_if_signed_in(db, "trip_tags", tag_id, op, &row).await?;
            // Any tag the caller links to a trip lands in their
            // personal library too.
            enqueue_user_tag(db, tag_id).await
        }
    }
}
