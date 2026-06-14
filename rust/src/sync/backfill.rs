//! Backfill helpers for trips that pre-date the user signing in.
//!
//! When a user creates trips while anonymous and then signs in, those
//! trips carry `owner_id IS NULL` and were never enqueued for push.
//! The "Upload these to my account" flow on the home screen:
//!   1. counts them so the UI can offer a button,
//!   2. on confirmation, claims them for the signed-in user and
//!      enqueues every row (trip + children) for push.

use std::ops::Deref;

use anyhow::{anyhow, Context};
use sea_orm::ActiveValue::Set;
use sea_orm::{ColumnTrait, EntityTrait, PaginatorTrait, QueryFilter};
use uuid::Uuid;

use crate::database::entities::accommodation::{self, Entity as Accommodation};
use crate::database::entities::accommodation_attachment::{
    self as accommodation_attachment, Entity as AccommodationAttachment,
};
use crate::database::entities::attachment::{self, Entity as Attachment};
use crate::database::entities::car_rental::{self, Entity as CarRental};
use crate::database::entities::location::{self, Entity as Location};
use crate::database::entities::location_attachment::Entity as LocationAttachment;
use crate::database::entities::pending_mutation::MutationOperation;
use crate::database::entities::point_of_interest::{self, Entity as PointOfInterest};
use crate::database::entities::reservation::{self, Entity as Reservation};
use crate::database::entities::tag::{self, Entity as Tag};
use crate::database::entities::train::{self, Entity as Train};
use crate::database::entities::trip::{self, Entity as Trip};
use crate::database::entities::trip_tag::{self, Entity as TripTag};
use crate::database::Database;
use crate::sync::{push, session, wire};

/// Number of trips on this device that haven't been pushed yet because
/// they were created while anonymous.
pub async fn count_local_only_trips(db: &Database) -> anyhow::Result<u64> {
    let count = Trip::find()
        .filter(trip::Column::OwnerId.is_null())
        .count(db.deref())
        .await?;
    Ok(count)
}

/// Claim every anonymous trip on this device for the signed-in user and
/// enqueue the full subtree for push. Returns the number of trips
/// claimed.
pub async fn upload_local_only_trips(db: &Database) -> anyhow::Result<u64> {
    let user_id = session::current_user()
        .await
        .ok_or_else(|| anyhow!("Sign in before uploading local trips"))?;

    let unowned = Trip::find()
        .filter(trip::Column::OwnerId.is_null())
        .all(db.deref())
        .await?;
    let total = unowned.len() as u64;
    for trip in unowned {
        claim_and_enqueue(db, &trip, user_id).await?;
    }
    Ok(total)
}

/// Claim a single trip the user owns (or pre-owned but never pushed) for
/// the signed-in user and enqueue its full subtree.
pub async fn upload_trip(db: &Database, trip_id: Uuid) -> anyhow::Result<()> {
    let user_id = session::current_user()
        .await
        .ok_or_else(|| anyhow!("Sign in before uploading this trip"))?;
    let trip = Trip::find_by_id(trip_id)
        .one(db.deref())
        .await?
        .ok_or_else(|| anyhow!("Trip not found"))?;
    claim_and_enqueue(db, &trip, user_id).await
}

async fn claim_and_enqueue(
    db: &Database,
    trip: &trip::Model,
    user_id: Uuid,
) -> anyhow::Result<()> {
    // Claim ownership locally if the trip is still anonymous so future
    // edits push correctly. Trips that already have an owner just get
    // re-enqueued so their subtree replays. Also clears `detached_at`
    // so a re-claimed previously-detached trip flips back to "synced".
    //
    // Anonymous trips with a local header image have no Storage path
    // yet — mint one now so the push worker uploads the blob before
    // sending the row.
    if trip.owner_id.is_none() {
        let now = chrono::Utc::now();
        let (header_path, header_sha) =
            if let (Some(bytes), None) = (trip.header_image.as_deref(), &trip.header_image_path) {
                use sha2::{Digest, Sha256};
                let mut hasher = Sha256::new();
                hasher.update(bytes);
                let sha = format!("{:x}", hasher.finalize());
                (
                    Some(wire::trip_header_storage_path(trip.id, Uuid::new_v4())),
                    Some(sha),
                )
            } else {
                (trip.header_image_path.clone(), trip.header_image_sha256.clone())
            };
        let claimed = trip::ActiveModel {
            id: Set(trip.id),
            owner_id: Set(Some(user_id.to_string())),
            updated_at: Set(now),
            last_modified_by: Set(Some(user_id.to_string())),
            detached_at: Set(None),
            header_image_path: Set(header_path),
            header_image_sha256: Set(header_sha),
            header_image_uploaded_at: Set(None),
            ..Default::default()
        };
        Trip::update(claimed).exec(db.deref()).await?;
    }

    let refreshed = Trip::find_by_id(trip.id)
        .one(db.deref())
        .await?
        .ok_or_else(|| anyhow!("trip vanished mid-backfill"))?;
    push::enqueue_if_signed_in(
        db,
        "trips",
        refreshed.id,
        MutationOperation::Insert,
        &wire::TripRow::from_model(&refreshed, user_id),
    )
    .await?;
    enqueue_trip_subtree(db, trip.id, user_id)
        .await
        .with_context(|| format!("enqueue subtree for trip {}", trip.id))?;
    Ok(())
}

async fn enqueue_trip_subtree(
    db: &Database,
    trip_id: Uuid,
    user_id: Uuid,
) -> anyhow::Result<()> {
    // Accommodations
    let accommodations = Accommodation::find()
        .filter(accommodation::Column::TripId.eq(trip_id))
        .all(db.deref())
        .await?;
    for m in &accommodations {
        push::enqueue_if_signed_in(
            db,
            "accommodations",
            m.id,
            MutationOperation::Insert,
            &wire::AccommodationRow::from_model(m),
        )
        .await?;
    }

    // Locations
    let locations = Location::find()
        .filter(location::Column::TripId.eq(trip_id))
        .all(db.deref())
        .await?;
    for m in &locations {
        push::enqueue_if_signed_in(
            db,
            "locations",
            m.id,
            MutationOperation::Insert,
            &wire::LocationRow::from_model(m),
        )
        .await?;
    }

    // Car rentals
    let car_rentals = CarRental::find()
        .filter(car_rental::Column::TripId.eq(trip_id))
        .all(db.deref())
        .await?;
    for m in &car_rentals {
        push::enqueue_if_signed_in(
            db,
            "car_rentals",
            m.id,
            MutationOperation::Insert,
            &wire::CarRentalRow::from_model(m),
        )
        .await?;
    }

    // Reservations
    let reservations = Reservation::find()
        .filter(reservation::Column::TripId.eq(trip_id))
        .all(db.deref())
        .await?;
    for m in &reservations {
        push::enqueue_if_signed_in(
            db,
            "reservations",
            m.id,
            MutationOperation::Insert,
            &wire::ReservationRow::from_model(m),
        )
        .await?;
    }

    // Points of interest
    let pois = PointOfInterest::find()
        .filter(point_of_interest::Column::TripId.eq(trip_id))
        .all(db.deref())
        .await?;
    for m in &pois {
        push::enqueue_if_signed_in(
            db,
            "points_of_interest",
            m.id,
            MutationOperation::Insert,
            &wire::PointOfInterestRow::from_model(m),
        )
        .await?;
    }

    // Trains
    let trains = Train::find()
        .filter(train::Column::TripId.eq(trip_id))
        .all(db.deref())
        .await?;
    for m in &trains {
        push::enqueue_if_signed_in(
            db,
            "trains",
            m.id,
            MutationOperation::Insert,
            &wire::TrainRow::from_model(m),
        )
        .await?;
    }

    // Attachments belonging to this trip — the push worker uploads the
    // blob to Storage on its own when it sees `uploaded_at IS NULL`.
    let attachments = Attachment::find()
        .filter(attachment::Column::TripId.eq(trip_id))
        .all(db.deref())
        .await?;
    for m in &attachments {
        if let Some(row) = wire::AttachmentRow::from_model(m) {
            push::enqueue_if_signed_in(
                db,
                "attachments",
                m.id,
                MutationOperation::Insert,
                &row,
            )
            .await?;
        }
    }

    // accommodation_attachments (composite key) — enqueue inserts for any
    // join row whose accommodation belongs to this trip.
    let accommodation_ids: Vec<Uuid> = accommodations.iter().map(|m| m.id).collect();
    if !accommodation_ids.is_empty() {
        let joins = AccommodationAttachment::find()
            .filter(accommodation_attachment::Column::AccommodationId.is_in(accommodation_ids))
            .all(db.deref())
            .await?;
        for j in joins {
            let row = wire::AccommodationAttachmentRow::from_model(&j);
            push::enqueue_if_signed_in(
                db,
                "accommodation_attachments",
                j.attachment_id,
                MutationOperation::Insert,
                &row,
            )
            .await?;
        }
    }

    // location_attachments — same pattern.
    let location_ids: Vec<Uuid> = locations.iter().map(|m| m.id).collect();
    if !location_ids.is_empty() {
        use crate::database::entities::location_attachment;
        let joins = LocationAttachment::find()
            .filter(location_attachment::Column::LocationId.is_in(location_ids))
            .all(db.deref())
            .await?;
        for j in joins {
            let row = wire::LocationAttachmentRow::from_model(&j);
            push::enqueue_if_signed_in(
                db,
                "location_attachments",
                j.attachment_id,
                MutationOperation::Insert,
                &row,
            )
            .await?;
        }
    }

    // trip_tags
    let tags_for_trip = TripTag::find()
        .filter(trip_tag::Column::TripId.eq(trip_id))
        .all(db.deref())
        .await?;
    for tt in &tags_for_trip {
        let row = wire::TripTagRow::from_model(tt);
        push::enqueue_if_signed_in(
            db,
            "trip_tags",
            tt.tag_id,
            MutationOperation::Insert,
            &row,
        )
        .await?;
    }

    // Tags themselves (the library entries the trip_tags reference).
    // Tags are append-only globally and ids are content-addressed by
    // lowercased name (uuid v5), so each local tag's id already
    // matches the canonical server id — no remap. The push worker's
    // INSERT either lands a new global row or hits the unique
    // constraint because someone else already typed the name. Every
    // tag the caller has touched here also becomes a user_tag, which
    // is what makes the tag show up in the caller's library on every
    // future device.
    if !tags_for_trip.is_empty() {
        let tag_ids: Vec<Uuid> = tags_for_trip.iter().map(|t| t.tag_id).collect();
        let tags = Tag::find()
            .filter(tag::Column::Id.is_in(tag_ids))
            .all(db.deref())
            .await?;
        for t in &tags {
            push::enqueue_if_signed_in(
                db,
                "tags",
                t.id,
                MutationOperation::Insert,
                &wire::TagRow::from_model(t),
            )
            .await?;
            crate::handlers::tag_handler::enqueue_user_tag(db, t.id).await?;
        }
    }

    Ok(())
}
