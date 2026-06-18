//! Apply a remote row (from pull or realtime) to local SQLite.
//!
//! All entry points enforce last-write-wins via `updated_at` comparison and
//! emit the same `DataChangeEvent`s as local mutations, so the UI cannot
//! tell apart "I edited" from "Alice edited on her phone".

use std::ops::Deref;

use sea_orm::ActiveValue::Set;
use sea_orm::EntityTrait;
use serde_json::Value;
use uuid::Uuid;

use chrono::{DateTime, Utc};

use crate::api::events::{self, DataChangeEvent};
use crate::database::entities::accommodation::{self, Entity as Accommodation};
use crate::database::entities::accommodation_attachment::{
    self as accommodation_attachment, Entity as AccommodationAttachment,
};
use crate::database::entities::attachment::{self, Entity as Attachment};
use crate::database::entities::car_rental::{self, Entity as CarRental};
use crate::database::entities::location::{self, Entity as Location};
use crate::database::entities::location_attachment::{
    self as location_attachment, Entity as LocationAttachment,
};
use crate::database::entities::point_of_interest::{self, Entity as PointOfInterest};
use crate::database::entities::profile::{self, Entity as Profile};
use crate::database::entities::reservation::{
    self, Entity as Reservation, ReservationCategory,
};
use crate::database::entities::route::{self, Entity as Route};
use crate::database::entities::tag::{self, Entity as Tag};
use crate::database::entities::trip_day::{self, Entity as TripDay};
use crate::database::entities::trip_day_location::{self, Entity as TripDayLocation};
use crate::database::entities::train::{self, Entity as Train};
use crate::database::entities::trip::{self, Entity as Trip};
use crate::database::entities::trip_activity::{self, Entity as TripActivity};
use crate::database::entities::trip_member::{self, Entity as TripMember};
use crate::database::entities::trip_tag::{self, Entity as TripTag};
use crate::database::entities::user_tag::{self, Entity as UserTag};
use crate::database::Database;
use crate::sync::wire::{
    parse_route_provider, AccommodationAttachmentRow, AccommodationRow, AttachmentRow, CarRentalRow,
    LocationAttachmentRow, LocationRow, PointOfInterestRow, ProfileRow, ReservationRow, RouteRow,
    TagRow, TrainRow, TripActivityRow, TripDayLocationRow, TripDayRow, TripMemberRow, TripRow,
    TripTagRow, UserTagRow, ATTACHMENTS_BUCKET,
};
use crate::sync::{coordinator, http, session};

pub async fn apply_remote_row(db: &Database, table: &str, row: Value) -> anyhow::Result<()> {
    // Pull/realtime both gate on a live session, but a sign-out can race
    // an in-flight apply. Bail rather than running detach / ownership
    // checks with `current_user() == None`, which would otherwise treat
    // every remote row as "owned by someone else" and falsely detach.
    if session::current_user().await.is_none() {
        return Ok(());
    }
    match table {
        "trips" => apply_trip(db, row).await,
        "attachments" => apply_attachment(db, row).await,
        "trip_members" => apply_trip_member(db, row).await,
        "profiles" => apply_profile(db, row).await,
        "accommodations" => apply_accommodation(db, row).await,
        "locations" => apply_location(db, row).await,
        "car_rentals" => apply_car_rental(db, row).await,
        "reservations" => apply_reservation(db, row).await,
        "points_of_interest" => apply_point_of_interest(db, row).await,
        "trains" => apply_train(db, row).await,
        "tags" => apply_tag(db, row).await,
        "user_tags" => apply_user_tag(db, row).await,
        "accommodation_attachments" => apply_accommodation_attachment(db, row).await,
        "location_attachments" => apply_location_attachment(db, row).await,
        "trip_tags" => apply_trip_tag(db, row).await,
        "trip_days" => apply_trip_day(db, row).await,
        "trip_day_locations" => apply_trip_day_location(db, row).await,
        "routes" => apply_route(db, row).await,
        "trip_activity" => apply_trip_activity(db, row).await,
        _ => {
            tracing::debug!("apply: ignoring unsupported table {table}");
            Ok(())
        }
    }
}

/// LWW comparison: returns `true` if `incoming` should be applied over
/// `local`. Deletes are terminal — once an entity is deleted, no later
/// edit can resurrect it, so a delete tombstone always wins.
fn incoming_wins(
    local_updated_at: DateTime<Utc>,
    incoming_updated_at: DateTime<Utc>,
    incoming_is_delete: bool,
) -> bool {
    if incoming_is_delete {
        return true;
    }
    incoming_updated_at > local_updated_at
}

/// True when the local copy of `trip_id` is owned by somebody other
/// than the current user. Used by every child-table delete branch to
/// recognise the owner's cascade-delete so we keep our last-fetched
/// snapshot instead of removing rows out from under the UI.
async fn trip_owned_by_other(db: &Database, trip_id: Uuid) -> anyhow::Result<bool> {
    let Some(local) = Trip::find_by_id(trip_id).one(db.deref()).await? else {
        return Ok(false);
    };
    let owner = local
        .owner_id
        .as_deref()
        .and_then(|s| Uuid::parse_str(s).ok());
    let me = session::current_user().await;
    Ok(owner.is_some() && owner != me)
}

/// Flip the local trip into the "detached" state. Apply-only flag — it
/// never round-trips to the server. We also clear `owner_id` so the
/// trip looks like an anonymous trip again, which lets the existing
/// "Sync to my account" flow claim it for the current user without a
/// separate code path.
async fn mark_trip_detached(db: &Database, trip_id: Uuid) -> anyhow::Result<()> {
    let active = trip::ActiveModel {
        id: Set(trip_id),
        detached_at: Set(Some(Utc::now())),
        owner_id: Set(None),
        ..Default::default()
    };
    Trip::update(active).exec(db.deref()).await?;
    events::emit(DataChangeEvent::TripsChanged);
    events::emit(DataChangeEvent::TripChanged { trip_id });
    Ok(())
}

async fn apply_trip(db: &Database, row: Value) -> anyhow::Result<()> {
    let incoming: TripRow = serde_json::from_value(row)
        .map_err(|e| anyhow::anyhow!("Failed to decode trip row: {e}"))?;

    let existing = Trip::find_by_id(incoming.id).one(db.deref()).await?;

    if let Some(local) = &existing {
        if !incoming_wins(local.updated_at, incoming.updated_at, incoming.deleted_at.is_some()) {
            tracing::debug!(
                "apply: skip trip {} — local {} >= remote {}",
                incoming.id, local.updated_at, incoming.updated_at,
            );
            return Ok(());
        }
    }

    // Soft-deleted row on the server → hard-delete locally, UNLESS we
    // were only a member of someone else's trip. In that case the owner
    // is tearing the trip down; we keep the last-fetched snapshot in a
    // detached state instead of dropping it.
    if incoming.deleted_at.is_some() {
        if let Some(local) = &existing {
            let owner = local
                .owner_id
                .as_deref()
                .and_then(|s| Uuid::parse_str(s).ok());
            let me = session::current_user().await;
            if owner.is_some() && owner != me && local.detached_at.is_none() {
                mark_trip_detached(db, incoming.id).await?;
                return Ok(());
            }
            Trip::delete_by_id(incoming.id).exec(db.deref()).await?;
            events::emit(DataChangeEvent::TripsChanged);
            events::emit(DataChangeEvent::TripChanged { trip_id: incoming.id });
        }
        return Ok(());
    }

    // Resolve the header image bytes before the upsert so the row only
    // becomes visible to the UI once any new blob is in place — avoids
    // a flicker through an empty-image state.
    let (header_bytes, header_path, header_sha, header_uploaded_at) =
        resolve_header_image(existing.as_ref(), &incoming).await?;

    let model = trip::ActiveModel {
        id: Set(incoming.id),
        name: Set(incoming.name),
        start_date: Set(incoming.start_date),
        end_date: Set(incoming.end_date),
        header_image: Set(header_bytes),
        updated_at: Set(incoming.updated_at),
        deleted_at: Set(incoming.deleted_at),
        last_modified_by: Set(incoming.last_modified_by.map(|u| u.to_string())),
        owner_id: Set(Some(incoming.owner_id.to_string())),
        header_image_path: Set(header_path),
        header_image_sha256: Set(header_sha),
        header_image_uploaded_at: Set(header_uploaded_at),
        ..Default::default()
    };

    if existing.is_some() {
        Trip::update(model).exec(db.deref()).await?;
    } else {
        Trip::insert(model)
            .exec_without_returning(db.deref())
            .await?;
    }

    events::emit(DataChangeEvent::TripsChanged);
    events::emit(DataChangeEvent::TripChanged { trip_id: incoming.id });
    Ok(())
}

/// Decide what header-image state the local row should end up with
/// after applying a remote trip row. Returns
/// `(bytes, path, sha256, uploaded_at)`.
///
/// - Remote has no header → drop ours.
/// - Remote sha matches local sha → reuse local bytes.
/// - Remote sha differs (or we have no bytes) → pull from Storage.
async fn resolve_header_image(
    local: Option<&trip::Model>,
    incoming: &crate::sync::wire::TripRow,
) -> anyhow::Result<(
    Option<Vec<u8>>,
    Option<String>,
    Option<String>,
    Option<DateTime<Utc>>,
)> {
    // Remote explicitly has no header → drop our local copy.
    if incoming.header_image_path.is_none() && incoming.header_image_sha256.is_none() {
        return Ok((None, None, None, None));
    }
    // Anomalous partial server row (path without sha, or vice versa).
    // Don't trust it to overwrite — preserve whatever local has so a
    // half-written server row can't cause permanent local data loss.
    let (Some(remote_path), Some(remote_sha)) = (
        incoming.header_image_path.clone(),
        incoming.header_image_sha256.clone(),
    ) else {
        tracing::warn!(
            "apply trip {}: remote header_image is half-populated (path={:?}, sha256={:?}); preserving local state",
            incoming.id,
            incoming.header_image_path,
            incoming.header_image_sha256,
        );
        return Ok((
            local.and_then(|m| m.header_image.clone()),
            local.and_then(|m| m.header_image_path.clone()),
            local.and_then(|m| m.header_image_sha256.clone()),
            local.and_then(|m| m.header_image_uploaded_at),
        ));
    };

    let local_matches = local
        .and_then(|m| m.header_image_sha256.as_deref())
        .map(|sha| sha == remote_sha)
        .unwrap_or(false);

    let bytes = if local_matches {
        local.and_then(|m| m.header_image.clone())
    } else {
        let downloaded = http::storage_download(ATTACHMENTS_BUCKET, &remote_path).await?;
        verify_sha256(&downloaded, &remote_sha)?;
        Some(downloaded)
    };

    // Don't downgrade uploaded_at: a local Some + remote None usually
    // means the pulling device is also the pushing device, and its
    // local push completed the upload while the server's view of the
    // row was still pre-upload. Trust the local timestamp over a stale
    // pull.
    let local_uploaded_at = local.and_then(|m| m.header_image_uploaded_at);
    let uploaded_at = match (local_uploaded_at, incoming.header_image_uploaded_at) {
        (Some(local_ts), Some(remote_ts)) => Some(local_ts.max(remote_ts)),
        (Some(local_ts), None) => Some(local_ts),
        (None, Some(remote_ts)) => Some(remote_ts),
        (None, None) => None,
    };

    Ok((bytes, Some(remote_path), Some(remote_sha), uploaded_at))
}

async fn apply_attachment(db: &Database, row: Value) -> anyhow::Result<()> {
    let incoming: AttachmentRow = serde_json::from_value(row)
        .map_err(|e| anyhow::anyhow!("Failed to decode attachment row: {e}"))?;

    let existing = Attachment::find_by_id(incoming.id).one(db.deref()).await?;

    if let Some(local) = &existing {
        if local.updated_at >= incoming.updated_at {
            tracing::debug!(
                "apply: skip attachment {} — local {} >= remote {}",
                incoming.id, local.updated_at, incoming.updated_at,
            );
            return Ok(());
        }
    }

    if incoming.deleted_at.is_some() {
        if trip_owned_by_other(db, incoming.trip_id).await? {
            return Ok(());
        }
        if existing.is_some() {
            Attachment::delete_by_id(incoming.id).exec(db.deref()).await?;
            emit_attachment_event(incoming.id, incoming.trip_id);
        }
        return Ok(());
    }

    // Decide whether we already have the bytes that match this row.
    let same_hash = existing
        .as_ref()
        .and_then(|m| m.sha256.as_ref())
        .map(|local| local == &incoming.sha256)
        .unwrap_or(false);

    let data = if same_hash {
        // Re-use what we already have.
        existing
            .as_ref()
            .map(|m| m.data.clone())
            .unwrap_or_default()
    } else {
        // Pull the bytes from Storage. If this fails the whole apply
        // fails and the realtime/pull layer retries later.
        let bytes = http::storage_download(ATTACHMENTS_BUCKET, &incoming.storage_path).await?;
        verify_sha256(&bytes, &incoming.sha256)?;
        bytes
    };

    let model = attachment::ActiveModel {
        id: Set(incoming.id),
        trip_id: Set(incoming.trip_id),
        name: Set(incoming.name),
        file_name: Set(incoming.file_name),
        content_type: Set(incoming.content_type),
        data: Set(data),
        updated_at: Set(incoming.updated_at),
        deleted_at: Set(incoming.deleted_at),
        last_modified_by: Set(incoming.last_modified_by.map(|u| u.to_string())),
        storage_path: Set(Some(incoming.storage_path)),
        sha256: Set(Some(incoming.sha256)),
        uploaded_at: Set(incoming.uploaded_at),
    };
    if existing.is_some() {
        Attachment::update(model).exec(db.deref()).await?;
    } else {
        Attachment::insert(model)
            .exec_without_returning(db.deref())
            .await?;
    }

    emit_attachment_event(incoming.id, incoming.trip_id);
    Ok(())
}

fn emit_attachment_event(_attachment_id: Uuid, trip_id: Uuid) {
    events::emit(DataChangeEvent::AttachmentsChanged {
        trip_id: Some(trip_id),
        accommodation_id: None,
    });
}

fn verify_sha256(bytes: &[u8], expected_hex: &str) -> anyhow::Result<()> {
    use sha2::{Digest, Sha256};
    let mut hasher = Sha256::new();
    hasher.update(bytes);
    let got = format!("{:x}", hasher.finalize());
    if got != expected_hex {
        anyhow::bail!(
            "Attachment hash mismatch: server claimed {expected_hex}, got {got}"
        );
    }
    Ok(())
}

async fn apply_trip_member(db: &Database, row: Value) -> anyhow::Result<()> {
    let incoming: TripMemberRow = serde_json::from_value(row)
        .map_err(|e| anyhow::anyhow!("Failed to decode trip_member row: {e}"))?;
    let trip_id = incoming.trip_id;
    let user_id = incoming.user_id;

    let existing = TripMember::find_by_id((trip_id, user_id)).one(db.deref()).await?;

    if let Some(local) = &existing {
        if local.updated_at >= incoming.updated_at {
            return Ok(());
        }
    }

    let was_present = existing.is_some();
    let new_model = incoming.into_model();
    let is_self = session::current_user().await == Some(user_id);
    let is_deletion = new_model.deleted_at.is_some();

    if is_deletion {
        // If the local trip is owned by someone else, this delete is
        // the owner's cascade — keep our membership row alongside the
        // detached trip so the local view stays consistent.
        if trip_owned_by_other(db, trip_id).await? {
            return Ok(());
        }
        if was_present {
            TripMember::delete_by_id((trip_id, user_id)).exec(db.deref()).await?;
        }
        events::emit(DataChangeEvent::TripMembersChanged { trip_id });
        if is_self {
            events::emit(DataChangeEvent::TripAccessRevoked { trip_id });
        }
        return Ok(());
    }

    let active = trip_member::ActiveModel {
        trip_id: Set(new_model.trip_id),
        user_id: Set(new_model.user_id),
        added_at: Set(new_model.added_at),
        updated_at: Set(new_model.updated_at),
        deleted_at: Set(new_model.deleted_at),
    };
    if was_present {
        TripMember::update(active).exec(db.deref()).await?;
    } else {
        TripMember::insert(active).exec_without_returning(db.deref()).await?;
    }

    events::emit(DataChangeEvent::TripMembersChanged { trip_id });
    if is_self && !was_present {
        // We just got added to a trip we didn't know about. Wake the
        // coordinator so it pulls the rest of the trip's data right
        // away rather than at the next 30 s tick — without this, the
        // user sees an empty trip in the list for up to half a minute.
        events::emit(DataChangeEvent::TripAccessGranted { trip_id });
        coordinator::request_pull();
    }
    Ok(())
}

async fn apply_accommodation(db: &Database, row: Value) -> anyhow::Result<()> {
    let incoming: AccommodationRow = serde_json::from_value(row)
        .map_err(|e| anyhow::anyhow!("decode accommodation: {e}"))?;
    let existing = Accommodation::find_by_id(incoming.id).one(db.deref()).await?;
    if let Some(local) = &existing {
        if !incoming_wins(local.updated_at, incoming.updated_at, incoming.deleted_at.is_some()) {
            return Ok(());
        }
    }
    if incoming.deleted_at.is_some() {
        if trip_owned_by_other(db, incoming.trip_id).await? {
            return Ok(());
        }
        if existing.is_some() {
            Accommodation::delete_by_id(incoming.id).exec(db.deref()).await?;
            events::emit(DataChangeEvent::AccommodationsChanged { trip_id: Some(incoming.trip_id) });
        }
        return Ok(());
    }
    // weather / pollen *_last_updated columns are per-device caches
    // populated by background jobs — keep whatever the local row has.
    let (weather_ts, pollen_ts) = match existing.as_ref() {
        Some(m) => (
            m.weather_information_last_updated,
            m.pollen_information_last_updated,
        ),
        None => (None, None),
    };
    let active = accommodation::ActiveModel {
        id: Set(incoming.id),
        trip_id: Set(incoming.trip_id),
        name: Set(incoming.name),
        check_in: Set(incoming.check_in),
        check_out: Set(incoming.check_out),
        address: Set(incoming.address),
        coordinates_latitude: Set(incoming.coordinates_latitude),
        coordinates_longitude: Set(incoming.coordinates_longitude),
        weather_information_last_updated: Set(weather_ts),
        pollen_information_last_updated: Set(pollen_ts),
        updated_at: Set(incoming.updated_at),
        deleted_at: Set(incoming.deleted_at),
        last_modified_by: Set(incoming.last_modified_by.map(|u| u.to_string())),
    };
    if existing.is_some() {
        Accommodation::update(active).exec(db.deref()).await?;
    } else {
        Accommodation::insert(active).exec_without_returning(db.deref()).await?;
    }
    events::emit(DataChangeEvent::AccommodationsChanged { trip_id: Some(incoming.trip_id) });
    Ok(())
}

async fn apply_location(db: &Database, row: Value) -> anyhow::Result<()> {
    let incoming: LocationRow = serde_json::from_value(row)
        .map_err(|e| anyhow::anyhow!("decode location: {e}"))?;
    let existing = Location::find_by_id(incoming.id).one(db.deref()).await?;
    if let Some(local) = &existing {
        if !incoming_wins(local.updated_at, incoming.updated_at, incoming.deleted_at.is_some()) {
            return Ok(());
        }
    }
    if incoming.deleted_at.is_some() {
        if trip_owned_by_other(db, incoming.trip_id).await? {
            return Ok(());
        }
        if existing.is_some() {
            Location::delete_by_id(incoming.id).exec(db.deref()).await?;
            events::emit(DataChangeEvent::LocationsChanged { trip_id: incoming.trip_id });
        }
        return Ok(());
    }
    // Keep locally-cached weather / tidal / pollen timestamps untouched
    // on update — they're derived per-device. New rows default to None.
    let (tidal_ts, weather_ts, pollen_ts) = match existing.as_ref() {
        Some(m) => (
            m.tidal_information_last_updated,
            m.weather_information_last_updated,
            m.pollen_information_last_updated,
        ),
        None => (None, None, None),
    };
    let active = location::ActiveModel {
        id: Set(incoming.id),
        trip_id: Set(incoming.trip_id),
        coordinates_latitude: Set(incoming.coordinates_latitude),
        coordinates_longitude: Set(incoming.coordinates_longitude),
        city: Set(incoming.city),
        country: Set(incoming.country),
        is_coastal: Set(incoming.is_coastal),
        tidal_information_last_updated: Set(tidal_ts),
        weather_information_last_updated: Set(weather_ts),
        pollen_information_last_updated: Set(pollen_ts),
        updated_at: Set(incoming.updated_at),
        deleted_at: Set(incoming.deleted_at),
        last_modified_by: Set(incoming.last_modified_by.map(|u| u.to_string())),
    };
    if existing.is_some() {
        Location::update(active).exec(db.deref()).await?;
    } else {
        Location::insert(active).exec_without_returning(db.deref()).await?;
    }
    events::emit(DataChangeEvent::LocationsChanged { trip_id: incoming.trip_id });
    Ok(())
}

async fn apply_car_rental(db: &Database, row: Value) -> anyhow::Result<()> {
    let incoming: CarRentalRow = serde_json::from_value(row)
        .map_err(|e| anyhow::anyhow!("decode car_rental: {e}"))?;
    let existing = CarRental::find_by_id(incoming.id).one(db.deref()).await?;
    if let Some(local) = &existing {
        if !incoming_wins(local.updated_at, incoming.updated_at, incoming.deleted_at.is_some()) {
            return Ok(());
        }
    }
    if incoming.deleted_at.is_some() {
        if trip_owned_by_other(db, incoming.trip_id).await? {
            return Ok(());
        }
        if existing.is_some() {
            CarRental::delete_by_id(incoming.id).exec(db.deref()).await?;
            events::emit(DataChangeEvent::BookingsChanged { trip_id: Some(incoming.trip_id) });
        }
        return Ok(());
    }
    let active = car_rental::ActiveModel {
        id: Set(incoming.id),
        trip_id: Set(incoming.trip_id),
        provider: Set(incoming.provider),
        pick_up_date: Set(incoming.pick_up_date),
        pick_up_location: Set(incoming.pick_up_location),
        return_date: Set(incoming.return_date),
        return_location: Set(incoming.return_location),
        booking_number: Set(incoming.booking_number),
        updated_at: Set(incoming.updated_at),
        deleted_at: Set(incoming.deleted_at),
        last_modified_by: Set(incoming.last_modified_by.map(|u| u.to_string())),
    };
    if existing.is_some() {
        CarRental::update(active).exec(db.deref()).await?;
    } else {
        CarRental::insert(active).exec_without_returning(db.deref()).await?;
    }
    events::emit(DataChangeEvent::BookingsChanged { trip_id: Some(incoming.trip_id) });
    Ok(())
}

async fn apply_reservation(db: &Database, row: Value) -> anyhow::Result<()> {
    let incoming: ReservationRow = serde_json::from_value(row)
        .map_err(|e| anyhow::anyhow!("decode reservation: {e}"))?;
    let existing = Reservation::find_by_id(incoming.id).one(db.deref()).await?;
    if let Some(local) = &existing {
        if !incoming_wins(local.updated_at, incoming.updated_at, incoming.deleted_at.is_some()) {
            return Ok(());
        }
    }
    if incoming.deleted_at.is_some() {
        if trip_owned_by_other(db, incoming.trip_id).await? {
            return Ok(());
        }
        if existing.is_some() {
            Reservation::delete_by_id(incoming.id).exec(db.deref()).await?;
            events::emit(DataChangeEvent::BookingsChanged { trip_id: Some(incoming.trip_id) });
        }
        return Ok(());
    }
    let category = match incoming.category.as_str() {
        "activity" => ReservationCategory::Activity,
        _ => ReservationCategory::Restaurant,
    };
    let active = reservation::ActiveModel {
        id: Set(incoming.id),
        trip_id: Set(incoming.trip_id),
        title: Set(incoming.title),
        address: Set(incoming.address),
        start_date: Set(incoming.start_date),
        end_date: Set(incoming.end_date),
        link: Set(incoming.link),
        booking_number: Set(incoming.booking_number),
        category: Set(category),
        updated_at: Set(incoming.updated_at),
        deleted_at: Set(incoming.deleted_at),
        last_modified_by: Set(incoming.last_modified_by.map(|u| u.to_string())),
    };
    if existing.is_some() {
        Reservation::update(active).exec(db.deref()).await?;
    } else {
        Reservation::insert(active).exec_without_returning(db.deref()).await?;
    }
    events::emit(DataChangeEvent::BookingsChanged { trip_id: Some(incoming.trip_id) });
    Ok(())
}

async fn apply_point_of_interest(db: &Database, row: Value) -> anyhow::Result<()> {
    let incoming: PointOfInterestRow = serde_json::from_value(row)
        .map_err(|e| anyhow::anyhow!("decode poi: {e}"))?;
    let existing = PointOfInterest::find_by_id(incoming.id).one(db.deref()).await?;
    if let Some(local) = &existing {
        if !incoming_wins(local.updated_at, incoming.updated_at, incoming.deleted_at.is_some()) {
            return Ok(());
        }
    }
    if incoming.deleted_at.is_some() {
        if trip_owned_by_other(db, incoming.trip_id).await? {
            return Ok(());
        }
        if existing.is_some() {
            PointOfInterest::delete_by_id(incoming.id).exec(db.deref()).await?;
            events::emit(DataChangeEvent::PoisChanged { trip_id: Some(incoming.trip_id) });
        }
        return Ok(());
    }
    let active = point_of_interest::ActiveModel {
        id: Set(incoming.id),
        trip_id: Set(incoming.trip_id),
        name: Set(incoming.name),
        address: Set(incoming.address),
        website: Set(incoming.website),
        opening_hours: Set(incoming.opening_hours),
        price: Set(incoming.price),
        phone_number: Set(incoming.phone_number),
        note: Set(incoming.note),
        coordinates_latitude: Set(incoming.coordinates_latitude),
        coordinates_longitude: Set(incoming.coordinates_longitude),
        trip_day_id: Set(incoming.trip_day_id),
        day_order: Set(incoming.day_order),
        scheduled_at: Set(incoming.scheduled_at),
        updated_at: Set(incoming.updated_at),
        deleted_at: Set(incoming.deleted_at),
        last_modified_by: Set(incoming.last_modified_by.map(|u| u.to_string())),
    };
    if existing.is_some() {
        PointOfInterest::update(active).exec(db.deref()).await?;
    } else {
        PointOfInterest::insert(active).exec_without_returning(db.deref()).await?;
    }
    events::emit(DataChangeEvent::PoisChanged { trip_id: Some(incoming.trip_id) });
    Ok(())
}

async fn apply_train(db: &Database, row: Value) -> anyhow::Result<()> {
    let incoming: TrainRow = serde_json::from_value(row)
        .map_err(|e| anyhow::anyhow!("decode train: {e}"))?;
    let existing = Train::find_by_id(incoming.id).one(db.deref()).await?;
    if let Some(local) = &existing {
        if !incoming_wins(local.updated_at, incoming.updated_at, incoming.deleted_at.is_some()) {
            return Ok(());
        }
    }
    if incoming.deleted_at.is_some() {
        if trip_owned_by_other(db, incoming.trip_id).await? {
            return Ok(());
        }
        if existing.is_some() {
            Train::delete_by_id(incoming.id).exec(db.deref()).await?;
            events::emit(DataChangeEvent::TransitsChanged { trip_id: Some(incoming.trip_id) });
        }
        return Ok(());
    }
    let active = train::ActiveModel {
        id: Set(incoming.id),
        trip_id: Set(incoming.trip_id),
        train_number: Set(incoming.train_number),
        departure_station_name: Set(incoming.departure_station_name),
        departure_station_city: Set(incoming.departure_station_city),
        departure_station_country: Set(incoming.departure_station_country),
        departure_scheduled_platform: Set(incoming.departure_scheduled_platform),
        arrival_station_name: Set(incoming.arrival_station_name),
        arrival_station_city: Set(incoming.arrival_station_city),
        arrival_station_country: Set(incoming.arrival_station_country),
        arrival_scheduled_platform: Set(incoming.arrival_scheduled_platform),
        scheduled_departure_time: Set(incoming.scheduled_departure_time),
        scheduled_arrival_time: Set(incoming.scheduled_arrival_time),
        updated_at: Set(incoming.updated_at),
        deleted_at: Set(incoming.deleted_at),
        last_modified_by: Set(incoming.last_modified_by.map(|u| u.to_string())),
    };
    if existing.is_some() {
        Train::update(active).exec(db.deref()).await?;
    } else {
        Train::insert(active).exec_without_returning(db.deref()).await?;
    }
    events::emit(DataChangeEvent::TransitsChanged { trip_id: Some(incoming.trip_id) });
    Ok(())
}

async fn apply_tag(db: &Database, row: Value) -> anyhow::Result<()> {
    // Tags are append-only globally — no deletes, no renames. The id
    // is deterministic from the name so colliding writes from
    // different clients converge on the same row. We still upsert here
    // so a stale local row left over from anonymous mode picks up the
    // canonical `name` casing + `created_by` from the server.
    let incoming: TagRow = serde_json::from_value(row)
        .map_err(|e| anyhow::anyhow!("decode tag: {e}"))?;
    let existing = Tag::find_by_id(incoming.id).one(db.deref()).await?;
    if let Some(local) = &existing {
        if local.updated_at >= incoming.updated_at {
            return Ok(());
        }
    }
    let active = tag::ActiveModel {
        id: Set(incoming.id),
        name: Set(incoming.name),
        updated_at: Set(incoming.updated_at),
    };
    if existing.is_some() {
        Tag::update(active).exec(db.deref()).await?;
    } else {
        Tag::insert(active).exec_without_returning(db.deref()).await?;
    }
    events::emit(DataChangeEvent::TagsChanged);
    Ok(())
}

async fn apply_user_tag(db: &Database, row: Value) -> anyhow::Result<()> {
    // user_tags has soft-delete semantics for "remove from my
    // library". An incoming row with deleted_at set means another
    // device asked us to forget this tag — hard-delete locally.
    let incoming: UserTagRow = serde_json::from_value(row)
        .map_err(|e| anyhow::anyhow!("decode user_tag: {e}"))?;
    let key = (incoming.user_id, incoming.tag_id);
    let existing = UserTag::find_by_id(key).one(db.deref()).await?;
    if let Some(local) = &existing {
        if !incoming_wins(local.updated_at, incoming.updated_at, incoming.deleted_at.is_some()) {
            return Ok(());
        }
    }
    if incoming.deleted_at.is_some() {
        if existing.is_some() {
            UserTag::delete_by_id(key).exec(db.deref()).await?;
            events::emit(DataChangeEvent::TagsChanged);
        }
        return Ok(());
    }
    let active = user_tag::ActiveModel {
        user_id: Set(incoming.user_id),
        tag_id: Set(incoming.tag_id),
        added_at: Set(incoming.added_at),
        updated_at: Set(incoming.updated_at),
        deleted_at: Set(incoming.deleted_at),
    };
    if existing.is_some() {
        UserTag::update(active).exec(db.deref()).await?;
    } else {
        UserTag::insert(active).exec_without_returning(db.deref()).await?;
    }
    events::emit(DataChangeEvent::TagsChanged);
    Ok(())
}

async fn apply_accommodation_attachment(db: &Database, row: Value) -> anyhow::Result<()> {
    let incoming: AccommodationAttachmentRow = serde_json::from_value(row)
        .map_err(|e| anyhow::anyhow!("decode accommodation_attachment: {e}"))?;
    let key = (incoming.accommodation_id, incoming.attachment_id);
    let existing = AccommodationAttachment::find_by_id(key).one(db.deref()).await?;
    if let Some(local) = &existing {
        if !incoming_wins(local.updated_at, incoming.updated_at, incoming.deleted_at.is_some()) {
            return Ok(());
        }
    }
    if incoming.deleted_at.is_some() {
        if let Some(parent) = Accommodation::find_by_id(incoming.accommodation_id)
            .one(db.deref())
            .await?
        {
            if trip_owned_by_other(db, parent.trip_id).await? {
                return Ok(());
            }
        }
        if existing.is_some() {
            AccommodationAttachment::delete_by_id(key).exec(db.deref()).await?;
            events::emit(DataChangeEvent::AttachmentsChanged {
                trip_id: None,
                accommodation_id: Some(incoming.accommodation_id),
            });
        }
        return Ok(());
    }
    let active = accommodation_attachment::ActiveModel {
        accommodation_id: Set(incoming.accommodation_id),
        attachment_id: Set(incoming.attachment_id),
        updated_at: Set(incoming.updated_at),
        deleted_at: Set(incoming.deleted_at),
    };
    if existing.is_some() {
        AccommodationAttachment::update(active).exec(db.deref()).await?;
    } else {
        AccommodationAttachment::insert(active).exec_without_returning(db.deref()).await?;
    }
    events::emit(DataChangeEvent::AttachmentsChanged {
        trip_id: None,
        accommodation_id: Some(incoming.accommodation_id),
    });
    Ok(())
}

async fn apply_location_attachment(db: &Database, row: Value) -> anyhow::Result<()> {
    let incoming: LocationAttachmentRow = serde_json::from_value(row)
        .map_err(|e| anyhow::anyhow!("decode location_attachment: {e}"))?;
    let key = (incoming.location_id, incoming.attachment_id);
    let existing = LocationAttachment::find_by_id(key).one(db.deref()).await?;
    if let Some(local) = &existing {
        if !incoming_wins(local.updated_at, incoming.updated_at, incoming.deleted_at.is_some()) {
            return Ok(());
        }
    }
    if incoming.deleted_at.is_some() {
        if let Some(parent) = Location::find_by_id(incoming.location_id)
            .one(db.deref())
            .await?
        {
            if trip_owned_by_other(db, parent.trip_id).await? {
                return Ok(());
            }
        }
        if existing.is_some() {
            LocationAttachment::delete_by_id(key).exec(db.deref()).await?;
            events::emit(DataChangeEvent::AttachmentsChanged {
                trip_id: None,
                accommodation_id: None,
            });
        }
        return Ok(());
    }
    let active = location_attachment::ActiveModel {
        location_id: Set(incoming.location_id),
        attachment_id: Set(incoming.attachment_id),
        updated_at: Set(incoming.updated_at),
        deleted_at: Set(incoming.deleted_at),
    };
    if existing.is_some() {
        LocationAttachment::update(active).exec(db.deref()).await?;
    } else {
        LocationAttachment::insert(active).exec_without_returning(db.deref()).await?;
    }
    events::emit(DataChangeEvent::AttachmentsChanged {
        trip_id: None,
        accommodation_id: None,
    });
    Ok(())
}

async fn apply_trip_tag(db: &Database, row: Value) -> anyhow::Result<()> {
    let incoming: TripTagRow = serde_json::from_value(row)
        .map_err(|e| anyhow::anyhow!("decode trip_tag: {e}"))?;
    let key = (incoming.trip_id, incoming.tag_id);
    let existing = TripTag::find_by_id(key).one(db.deref()).await?;
    if let Some(local) = &existing {
        if !incoming_wins(local.updated_at, incoming.updated_at, incoming.deleted_at.is_some()) {
            return Ok(());
        }
    }
    if incoming.deleted_at.is_some() {
        if trip_owned_by_other(db, incoming.trip_id).await? {
            return Ok(());
        }
        if existing.is_some() {
            TripTag::delete_by_id(key).exec(db.deref()).await?;
            events::emit(DataChangeEvent::TagsChanged);
            events::emit(DataChangeEvent::TripChanged { trip_id: incoming.trip_id });
        }
        return Ok(());
    }
    let active = trip_tag::ActiveModel {
        trip_id: Set(incoming.trip_id),
        tag_id: Set(incoming.tag_id),
        updated_at: Set(incoming.updated_at),
        deleted_at: Set(incoming.deleted_at),
    };
    if existing.is_some() {
        TripTag::update(active).exec(db.deref()).await?;
    } else {
        TripTag::insert(active).exec_without_returning(db.deref()).await?;
    }
    events::emit(DataChangeEvent::TagsChanged);
    events::emit(DataChangeEvent::TripChanged { trip_id: incoming.trip_id });
    Ok(())
}

async fn apply_trip_activity(db: &Database, row: Value) -> anyhow::Result<()> {
    // Cascade-delete events on the activity log show up here with a
    // synthetic `deleted_at`. Drop them: the log is append-only on the
    // client and we want to keep it intact for detached trips.
    if row.get("deleted_at").and_then(|v| v.as_str()).is_some() {
        return Ok(());
    }
    let incoming: TripActivityRow = serde_json::from_value(row)
        .map_err(|e| anyhow::anyhow!("decode trip_activity: {e}"))?;
    let trip_id = incoming.trip_id;
    let model = incoming.into_model();
    let existing = TripActivity::find_by_id(model.id).one(db.deref()).await?;
    let active = trip_activity::ActiveModel {
        id: Set(model.id),
        trip_id: Set(model.trip_id),
        entity_type: Set(model.entity_type),
        entity_id: Set(model.entity_id),
        entity_label: Set(model.entity_label),
        action: Set(model.action),
        actor_user_id: Set(model.actor_user_id),
        occurred_at: Set(model.occurred_at),
    };
    if existing.is_some() {
        TripActivity::update(active).exec(db.deref()).await?;
    } else {
        TripActivity::insert(active).exec_without_returning(db.deref()).await?;
    }
    events::emit(DataChangeEvent::TripActivityChanged { trip_id });
    Ok(())
}

async fn apply_profile(db: &Database, row: Value) -> anyhow::Result<()> {
    let incoming: ProfileRow = serde_json::from_value(row)
        .map_err(|e| anyhow::anyhow!("Failed to decode profile row: {e}"))?;

    let existing = Profile::find_by_id(incoming.id).one(db.deref()).await?;
    if let Some(local) = &existing {
        if local.updated_at >= incoming.updated_at {
            return Ok(());
        }
    }

    let model = incoming.into_model();
    let active = profile::ActiveModel {
        id: Set(model.id),
        email: Set(model.email),
        display_name: Set(model.display_name),
        updated_at: Set(model.updated_at),
        deleted_at: Set(model.deleted_at),
    };
    if existing.is_some() {
        Profile::update(active).exec(db.deref()).await?;
    } else {
        Profile::insert(active).exec_without_returning(db.deref()).await?;
    }
    Ok(())
}

async fn apply_trip_day(db: &Database, row: Value) -> anyhow::Result<()> {
    let incoming: TripDayRow = serde_json::from_value(row)
        .map_err(|e| anyhow::anyhow!("decode trip_day: {e}"))?;
    let existing = TripDay::find_by_id(incoming.id).one(db.deref()).await?;
    if let Some(local) = &existing {
        if !incoming_wins(local.updated_at, incoming.updated_at, incoming.deleted_at.is_some()) {
            return Ok(());
        }
    }
    if incoming.deleted_at.is_some() {
        if trip_owned_by_other(db, incoming.trip_id).await? {
            return Ok(());
        }
        if existing.is_some() {
            TripDay::delete_by_id(incoming.id).exec(db.deref()).await?;
            events::emit(DataChangeEvent::TripDaysChanged { trip_id: incoming.trip_id });
        }
        return Ok(());
    }
    let active = trip_day::ActiveModel {
        id: Set(incoming.id),
        trip_id: Set(incoming.trip_id),
        date: Set(incoming.date),
        title: Set(incoming.title),
        updated_at: Set(incoming.updated_at),
        deleted_at: Set(incoming.deleted_at),
        last_modified_by: Set(incoming.last_modified_by.map(|u| u.to_string())),
    };
    if existing.is_some() {
        TripDay::update(active).exec(db.deref()).await?;
    } else {
        TripDay::insert(active).exec_without_returning(db.deref()).await?;
    }
    events::emit(DataChangeEvent::TripDaysChanged { trip_id: incoming.trip_id });
    Ok(())
}

async fn apply_trip_day_location(db: &Database, row: Value) -> anyhow::Result<()> {
    let incoming: TripDayLocationRow = serde_json::from_value(row)
        .map_err(|e| anyhow::anyhow!("decode trip_day_location: {e}"))?;
    let key = (incoming.trip_day_id, incoming.location_id);
    let existing = TripDayLocation::find_by_id(key).one(db.deref()).await?;
    if let Some(local) = &existing {
        if !incoming_wins(local.updated_at, incoming.updated_at, incoming.deleted_at.is_some()) {
            return Ok(());
        }
    }
    // Resolve trip_id via the trip_day so we can defer to the
    // detached-trip rule and emit a targeted event.
    let trip_id = match TripDay::find_by_id(incoming.trip_day_id).one(db.deref()).await? {
        Some(day) => Some(day.trip_id),
        None => None,
    };
    if incoming.deleted_at.is_some() {
        if let Some(tid) = trip_id {
            if trip_owned_by_other(db, tid).await? {
                return Ok(());
            }
        }
        if existing.is_some() {
            TripDayLocation::delete_by_id(key).exec(db.deref()).await?;
            if let Some(tid) = trip_id {
                events::emit(DataChangeEvent::TripDaysChanged { trip_id: tid });
            }
        }
        return Ok(());
    }
    let active = trip_day_location::ActiveModel {
        trip_day_id: Set(incoming.trip_day_id),
        location_id: Set(incoming.location_id),
        is_primary: Set(incoming.is_primary),
        display_order: Set(incoming.display_order),
        updated_at: Set(incoming.updated_at),
        deleted_at: Set(incoming.deleted_at),
    };
    if existing.is_some() {
        TripDayLocation::update(active).exec(db.deref()).await?;
    } else {
        TripDayLocation::insert(active).exec_without_returning(db.deref()).await?;
    }
    if let Some(tid) = trip_id {
        events::emit(DataChangeEvent::TripDaysChanged { trip_id: tid });
    }
    Ok(())
}

async fn apply_route(db: &Database, row: Value) -> anyhow::Result<()> {
    let incoming: RouteRow = serde_json::from_value(row)
        .map_err(|e| anyhow::anyhow!("decode route: {e}"))?;
    let existing = Route::find_by_id(incoming.id).one(db.deref()).await?;
    if let Some(local) = &existing {
        if !incoming_wins(local.updated_at, incoming.updated_at, incoming.deleted_at.is_some()) {
            return Ok(());
        }
    }
    if incoming.deleted_at.is_some() {
        if trip_owned_by_other(db, incoming.trip_id).await? {
            return Ok(());
        }
        if existing.is_some() {
            Route::delete_by_id(incoming.id).exec(db.deref()).await?;
            events::emit(DataChangeEvent::RoutesChanged { trip_id: Some(incoming.trip_id) });
        }
        return Ok(());
    }
    let active = route::ActiveModel {
        id: Set(incoming.id),
        trip_id: Set(incoming.trip_id),
        provider: Set(parse_route_provider(&incoming.provider)),
        provider_route_id: Set(incoming.provider_route_id),
        name: Set(incoming.name),
        sport: Set(incoming.sport),
        distance_meters: Set(incoming.distance_meters),
        duration_seconds: Set(incoming.duration_seconds),
        elevation_up_meters: Set(incoming.elevation_up_meters),
        elevation_down_meters: Set(incoming.elevation_down_meters),
        start_latitude: Set(incoming.start_latitude),
        start_longitude: Set(incoming.start_longitude),
        polyline: Set(incoming.polyline),
        note: Set(incoming.note),
        external_url: Set(incoming.external_url),
        trip_day_id: Set(incoming.trip_day_id),
        day_order: Set(incoming.day_order),
        scheduled_at: Set(incoming.scheduled_at),
        updated_at: Set(incoming.updated_at),
        deleted_at: Set(incoming.deleted_at),
        last_modified_by: Set(incoming.last_modified_by.map(|u| u.to_string())),
    };
    if existing.is_some() {
        Route::update(active).exec(db.deref()).await?;
    } else {
        Route::insert(active).exec_without_returning(db.deref()).await?;
    }
    events::emit(DataChangeEvent::RoutesChanged { trip_id: Some(incoming.trip_id) });
    Ok(())
}
