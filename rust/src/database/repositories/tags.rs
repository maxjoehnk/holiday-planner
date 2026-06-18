use std::ops::Deref;
use crate::database::entities::tag::{self, Entity as Tag};
use crate::database::entities::trip_tag::{self, Entity as TripTag};
use sea_orm::{EntityTrait, QueryOrder, QueryFilter, ColumnTrait};
use sea_orm::ActiveValue::Set;
use uuid::Uuid;
use crate::database::Database;

pub async fn find_all(db: &Database) -> anyhow::Result<Vec<tag::Model>> {
    let tags = Tag::find()
        .order_by_asc(tag::Column::Name)
        .all(db.deref())
        .await?;

    Ok(tags)
}

pub async fn find_by_id(db: &Database, id: Uuid) -> anyhow::Result<Option<tag::Model>> {
    let tag = Tag::find_by_id(id)
        .one(db.deref())
        .await?;

    Ok(tag)
}

/// Insert a new tag with the content-addressed id. Idempotent: if a
/// row with the same id already exists locally (someone already
/// created this tag, possibly via pull from a shared trip), this
/// returns the existing model unchanged.
pub async fn create(db: &Database, name: String) -> anyhow::Result<tag::Model> {
    use crate::sync::wire::tag_id_for_name;
    let id = tag_id_for_name(&name);
    if let Some(existing) = Tag::find_by_id(id).one(db.deref()).await? {
        return Ok(existing);
    }
    let model = tag::ActiveModel {
        id: Set(id),
        name: Set(name),
        updated_at: Set(chrono::Utc::now()),
    };

    Tag::insert(model)
        .exec_without_returning(db.deref())
        .await?;

    let tag = Tag::find_by_id(id)
        .one(db.deref())
        .await?
        .unwrap();

    Ok(tag)
}

pub async fn find_by_trip_id(db: &Database, trip_id: Uuid) -> anyhow::Result<Vec<tag::Model>> {
    let tags = Tag::find()
        .inner_join(TripTag)
        .filter(trip_tag::Column::TripId.eq(trip_id))
        .order_by_asc(tag::Column::Name)
        .all(db.deref())
        .await?;

    Ok(tags)
}

pub async fn add_tag_to_trip(db: &Database, trip_id: Uuid, tag_id: Uuid) -> anyhow::Result<()> {
    let model = trip_tag::ActiveModel {
        trip_id: Set(trip_id),
        tag_id: Set(tag_id),
        updated_at: Set(chrono::Utc::now()),
        ..Default::default()
    };
    
    TripTag::insert(model)
        .exec_without_returning(db.deref())
        .await?;

    Ok(())
}

pub async fn remove_tag_from_trip(db: &Database, trip_id: Uuid, tag_id: Uuid) -> anyhow::Result<()> {
    TripTag::delete_many()
        .filter(trip_tag::Column::TripId.eq(trip_id))
        .filter(trip_tag::Column::TagId.eq(tag_id))
        .exec(db.deref())
        .await?;

    Ok(())
}

pub async fn clear_trip_tags(db: &Database, trip_id: Uuid) -> anyhow::Result<()> {
    TripTag::delete_many()
        .filter(trip_tag::Column::TripId.eq(trip_id))
        .exec(db.deref())
        .await?;

    Ok(())
}
