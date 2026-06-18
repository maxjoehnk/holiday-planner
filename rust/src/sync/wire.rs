//! JSON wire format for entities pushed/pulled via PostgREST.
//!
//! These structs intentionally diverge from the SeaORM `Model` types in two
//! ways:
//! 1. They omit local-only / derived fields (e.g. attachment blobs that live
//!    in Storage, weather caches).
//! 2. They use string-typed IDs/timestamps because PostgREST returns and
//!    accepts JSON.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::database::entities::{
    accommodation, accommodation_attachment, attachment, car_rental, location, location_attachment,
    point_of_interest, profile, reservation, route, tag, train, trip, trip_activity, trip_day,
    trip_day_location, trip_member, trip_tag, user_tag,
};
use crate::database::entities::route::RouteProvider;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TripRow {
    pub id: Uuid,
    pub owner_id: Uuid,
    pub name: String,
    pub start_date: DateTime<Utc>,
    pub end_date: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub deleted_at: Option<DateTime<Utc>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub last_modified_by: Option<Uuid>,
    // Header image lives in the `attachments` Storage bucket. We carry
    // the path + sha256 + uploaded_at so other clients can pull the
    // blob; the raw bytes never go on the wire.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub header_image_path: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub header_image_sha256: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub header_image_uploaded_at: Option<DateTime<Utc>>,
}

impl TripRow {
    pub fn from_model(model: &trip::Model, owner_id: Uuid) -> Self {
        Self {
            id: model.id,
            owner_id,
            name: model.name.clone(),
            start_date: model.start_date,
            end_date: model.end_date,
            updated_at: model.updated_at,
            deleted_at: model.deleted_at,
            last_modified_by: model
                .last_modified_by
                .as_deref()
                .and_then(|s| Uuid::parse_str(s).ok()),
            header_image_path: model.header_image_path.clone(),
            header_image_sha256: model.header_image_sha256.clone(),
            header_image_uploaded_at: model.header_image_uploaded_at,
        }
    }
}

/// Canonical Storage object key for a trip's header image. The random
/// suffix is bumped on every byte change so other clients pick up the
/// new file via a path diff rather than an HTTP-cache invalidation.
pub fn trip_header_storage_path(trip_id: Uuid, key: Uuid) -> String {
    format!("trips/{trip_id}/header_{key}")
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AttachmentRow {
    pub id: Uuid,
    pub trip_id: Uuid,
    pub name: String,
    pub file_name: String,
    pub content_type: String,
    pub storage_path: String,
    pub sha256: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub uploaded_at: Option<DateTime<Utc>>,
    pub updated_at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub deleted_at: Option<DateTime<Utc>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub last_modified_by: Option<Uuid>,
}

impl AttachmentRow {
    pub fn from_model(model: &attachment::Model) -> Option<Self> {
        let storage_path = model.storage_path.clone()?;
        let sha256 = model.sha256.clone()?;
        Some(Self {
            id: model.id,
            trip_id: model.trip_id,
            name: model.name.clone(),
            file_name: model.file_name.clone(),
            content_type: model.content_type.clone(),
            storage_path,
            sha256,
            uploaded_at: model.uploaded_at,
            updated_at: model.updated_at,
            deleted_at: model.deleted_at,
            last_modified_by: model
                .last_modified_by
                .as_deref()
                .and_then(|s| Uuid::parse_str(s).ok()),
        })
    }
}

/// Canonical Storage object key for an attachment.
pub fn attachment_storage_path(trip_id: Uuid, attachment_id: Uuid) -> String {
    format!("trips/{trip_id}/{attachment_id}")
}

/// The Storage bucket attachment blobs live in.
pub const ATTACHMENTS_BUCKET: &str = "attachments";

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TripMemberRow {
    pub trip_id: Uuid,
    pub user_id: Uuid,
    pub added_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    #[serde(default)]
    pub deleted_at: Option<DateTime<Utc>>,
}

impl TripMemberRow {
    pub fn into_model(self) -> trip_member::Model {
        trip_member::Model {
            trip_id: self.trip_id,
            user_id: self.user_id,
            added_at: self.added_at,
            updated_at: self.updated_at,
            deleted_at: self.deleted_at,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProfileRow {
    pub id: Uuid,
    pub email: String,
    #[serde(default)]
    pub display_name: Option<String>,
    pub updated_at: DateTime<Utc>,
}

impl ProfileRow {
    pub fn into_model(self) -> profile::Model {
        profile::Model {
            id: self.id,
            email: self.email,
            display_name: self.display_name,
            updated_at: self.updated_at,
            deleted_at: None,
        }
    }
}

// =====================================================================
// Trip-scoped entities — same shape as their SeaORM Model but with
// chrono / Uuid types ready for JSON.
// =====================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AccommodationRow {
    pub id: Uuid,
    pub trip_id: Uuid,
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub check_in: Option<DateTime<Utc>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub check_out: Option<DateTime<Utc>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub address: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub coordinates_latitude: Option<f64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub coordinates_longitude: Option<f64>,
    pub updated_at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub deleted_at: Option<DateTime<Utc>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub last_modified_by: Option<Uuid>,
}

impl AccommodationRow {
    pub fn from_model(m: &accommodation::Model) -> Self {
        Self {
            id: m.id,
            trip_id: m.trip_id,
            name: m.name.clone(),
            check_in: m.check_in,
            check_out: m.check_out,
            address: m.address.clone(),
            coordinates_latitude: m.coordinates_latitude,
            coordinates_longitude: m.coordinates_longitude,
            updated_at: m.updated_at,
            deleted_at: m.deleted_at,
            last_modified_by: parse_uuid_opt(m.last_modified_by.as_deref()),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LocationRow {
    pub id: Uuid,
    pub trip_id: Uuid,
    pub coordinates_latitude: f64,
    pub coordinates_longitude: f64,
    pub city: String,
    pub country: String,
    pub is_coastal: bool,
    pub updated_at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub deleted_at: Option<DateTime<Utc>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub last_modified_by: Option<Uuid>,
}

impl LocationRow {
    pub fn from_model(m: &location::Model) -> Self {
        Self {
            id: m.id,
            trip_id: m.trip_id,
            coordinates_latitude: m.coordinates_latitude,
            coordinates_longitude: m.coordinates_longitude,
            city: m.city.clone(),
            country: m.country.clone(),
            is_coastal: m.is_coastal,
            updated_at: m.updated_at,
            deleted_at: m.deleted_at,
            last_modified_by: parse_uuid_opt(m.last_modified_by.as_deref()),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CarRentalRow {
    pub id: Uuid,
    pub trip_id: Uuid,
    pub provider: String,
    pub pick_up_date: DateTime<Utc>,
    pub pick_up_location: String,
    pub return_date: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub return_location: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub booking_number: Option<String>,
    pub updated_at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub deleted_at: Option<DateTime<Utc>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub last_modified_by: Option<Uuid>,
}

impl CarRentalRow {
    pub fn from_model(m: &car_rental::Model) -> Self {
        Self {
            id: m.id,
            trip_id: m.trip_id,
            provider: m.provider.clone(),
            pick_up_date: m.pick_up_date,
            pick_up_location: m.pick_up_location.clone(),
            return_date: m.return_date,
            return_location: m.return_location.clone(),
            booking_number: m.booking_number.clone(),
            updated_at: m.updated_at,
            deleted_at: m.deleted_at,
            last_modified_by: parse_uuid_opt(m.last_modified_by.as_deref()),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReservationRow {
    pub id: Uuid,
    pub trip_id: Uuid,
    pub title: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub address: Option<String>,
    pub start_date: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub end_date: Option<DateTime<Utc>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub link: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub booking_number: Option<String>,
    /// "restaurant" | "activity"
    pub category: String,
    pub updated_at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub deleted_at: Option<DateTime<Utc>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub last_modified_by: Option<Uuid>,
}

impl ReservationRow {
    pub fn from_model(m: &reservation::Model) -> Self {
        use crate::database::entities::reservation::ReservationCategory;
        let category = match m.category {
            ReservationCategory::Restaurant => "restaurant",
            ReservationCategory::Activity => "activity",
        }
        .to_string();
        Self {
            id: m.id,
            trip_id: m.trip_id,
            title: m.title.clone(),
            address: m.address.clone(),
            start_date: m.start_date,
            end_date: m.end_date,
            link: m.link.clone(),
            booking_number: m.booking_number.clone(),
            category,
            updated_at: m.updated_at,
            deleted_at: m.deleted_at,
            last_modified_by: parse_uuid_opt(m.last_modified_by.as_deref()),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PointOfInterestRow {
    pub id: Uuid,
    pub trip_id: Uuid,
    pub name: String,
    pub address: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub website: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub opening_hours: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub price: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub phone_number: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub coordinates_latitude: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub coordinates_longitude: Option<f64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub trip_day_id: Option<Uuid>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub day_order: Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub scheduled_at: Option<DateTime<Utc>>,
    pub updated_at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub deleted_at: Option<DateTime<Utc>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub last_modified_by: Option<Uuid>,
}

impl PointOfInterestRow {
    pub fn from_model(m: &point_of_interest::Model) -> Self {
        Self {
            id: m.id,
            trip_id: m.trip_id,
            name: m.name.clone(),
            address: m.address.clone(),
            website: m.website.clone(),
            opening_hours: m.opening_hours.clone(),
            price: m.price.clone(),
            phone_number: m.phone_number.clone(),
            note: m.note.clone(),
            coordinates_latitude: m.coordinates_latitude,
            coordinates_longitude: m.coordinates_longitude,
            trip_day_id: m.trip_day_id,
            day_order: m.day_order,
            scheduled_at: m.scheduled_at,
            updated_at: m.updated_at,
            deleted_at: m.deleted_at,
            last_modified_by: parse_uuid_opt(m.last_modified_by.as_deref()),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TrainRow {
    pub id: Uuid,
    pub trip_id: Uuid,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub train_number: Option<String>,
    pub departure_station_name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub departure_station_city: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub departure_station_country: Option<String>,
    pub departure_scheduled_platform: String,
    pub arrival_station_name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub arrival_station_city: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub arrival_station_country: Option<String>,
    pub arrival_scheduled_platform: String,
    pub scheduled_departure_time: DateTime<Utc>,
    pub scheduled_arrival_time: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub deleted_at: Option<DateTime<Utc>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub last_modified_by: Option<Uuid>,
}

impl TrainRow {
    pub fn from_model(m: &train::Model) -> Self {
        Self {
            id: m.id,
            trip_id: m.trip_id,
            train_number: m.train_number.clone(),
            departure_station_name: m.departure_station_name.clone(),
            departure_station_city: m.departure_station_city.clone(),
            departure_station_country: m.departure_station_country.clone(),
            departure_scheduled_platform: m.departure_scheduled_platform.clone(),
            arrival_station_name: m.arrival_station_name.clone(),
            arrival_station_city: m.arrival_station_city.clone(),
            arrival_station_country: m.arrival_station_country.clone(),
            arrival_scheduled_platform: m.arrival_scheduled_platform.clone(),
            scheduled_departure_time: m.scheduled_departure_time,
            scheduled_arrival_time: m.scheduled_arrival_time,
            updated_at: m.updated_at,
            deleted_at: m.deleted_at,
            last_modified_by: parse_uuid_opt(m.last_modified_by.as_deref()),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TagRow {
    pub id: Uuid,
    pub name: String,
    pub updated_at: DateTime<Utc>,
}

impl TagRow {
    pub fn from_model(m: &tag::Model) -> Self {
        Self {
            id: m.id,
            name: m.name.clone(),
            updated_at: m.updated_at,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserTagRow {
    pub user_id: Uuid,
    pub tag_id: Uuid,
    pub added_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub deleted_at: Option<DateTime<Utc>>,
}

impl UserTagRow {
    pub fn from_model(m: &user_tag::Model) -> Self {
        Self {
            user_id: m.user_id,
            tag_id: m.tag_id,
            added_at: m.added_at,
            updated_at: m.updated_at,
            deleted_at: m.deleted_at,
        }
    }
}

/// Namespace UUID for content-addressed tag ids. Combined with the
/// lowercased tag name via UUID v5, this guarantees every client
/// derives the same id for a given name so a sign-in / merge step
/// isn't needed: the local id already matches the server's canonical
/// id for that name. The constant is arbitrary but must never change.
const TAG_NAMESPACE: Uuid = Uuid::from_u128(0x4f7e_5b88_2b3a_4c6d_8e9f_1a2b3c4d5e6f);

/// Derive the canonical tag id for a name. Whitespace is trimmed and
/// the name is folded to lowercase so "Beach" and "beach" collapse to
/// the same id; the original case is preserved in the `name` column
/// for display.
pub fn tag_id_for_name(name: &str) -> Uuid {
    let normalized = name.trim().to_lowercase();
    Uuid::new_v5(&TAG_NAMESPACE, normalized.as_bytes())
}

/// Namespace for content-addressed trip_day ids. Two devices creating
/// the day-planner row for the same (trip, date) pair derive the same
/// id, so the unique `(trip_id, date)` constraint on the server can't
/// fire on cross-device collisions. The local PK insert is idempotent
/// for the same reason. Arbitrary constant, must never change.
const TRIP_DAY_NAMESPACE: Uuid = Uuid::from_u128(0x9c4b_8a17_3f5d_4a82_b6e1_7d2f8c4a5b9e);

/// Derive the canonical trip_day id for `(trip_id, date)`.
pub fn trip_day_id_for(trip_id: Uuid, date: chrono::NaiveDate) -> Uuid {
    let payload = format!("{trip_id}|{date}");
    Uuid::new_v5(&TRIP_DAY_NAMESPACE, payload.as_bytes())
}

/// Namespace for content-addressed route ids. Routes are imported
/// from external providers (currently Komoot) and have a
/// `(trip_id, provider, provider_route_id)` unique constraint on
/// the server. Without deterministic ids, two members of a shared
/// trip importing the same tour offline would each derive a fresh
/// uuid_v4 and one push would 409 on that constraint. Arbitrary
/// constant, must never change.
const ROUTE_NAMESPACE: Uuid = Uuid::from_u128(0x1b8c_2d63_4e95_4a73_a92e_8c4d6f5b7d1a);

/// Derive the canonical route id for
/// `(trip_id, provider, provider_route_id)`.
pub fn route_id_for(trip_id: Uuid, provider: &str, provider_route_id: &str) -> Uuid {
    let payload = format!("{trip_id}|{provider}|{provider_route_id}");
    Uuid::new_v5(&ROUTE_NAMESPACE, payload.as_bytes())
}

// =====================================================================
// Join tables — composite-key rows, no last_modified_by.
// =====================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AccommodationAttachmentRow {
    pub accommodation_id: Uuid,
    pub attachment_id: Uuid,
    pub updated_at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub deleted_at: Option<DateTime<Utc>>,
}

impl AccommodationAttachmentRow {
    pub fn from_model(m: &accommodation_attachment::Model) -> Self {
        Self {
            accommodation_id: m.accommodation_id,
            attachment_id: m.attachment_id,
            updated_at: m.updated_at,
            deleted_at: m.deleted_at,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LocationAttachmentRow {
    pub location_id: Uuid,
    pub attachment_id: Uuid,
    pub updated_at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub deleted_at: Option<DateTime<Utc>>,
}

impl LocationAttachmentRow {
    pub fn from_model(m: &location_attachment::Model) -> Self {
        Self {
            location_id: m.location_id,
            attachment_id: m.attachment_id,
            updated_at: m.updated_at,
            deleted_at: m.deleted_at,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TripTagRow {
    pub trip_id: Uuid,
    pub tag_id: Uuid,
    pub updated_at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub deleted_at: Option<DateTime<Utc>>,
}

impl TripTagRow {
    pub fn from_model(m: &trip_tag::Model) -> Self {
        Self {
            trip_id: m.trip_id,
            tag_id: m.tag_id,
            updated_at: m.updated_at,
            deleted_at: m.deleted_at,
        }
    }
}

fn parse_uuid_opt(s: Option<&str>) -> Option<Uuid> {
    s.and_then(|s| Uuid::parse_str(s).ok())
}

// =====================================================================
// trip_activity — server-populated, client read-only.
// =====================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TripActivityRow {
    pub id: Uuid,
    pub trip_id: Uuid,
    pub entity_type: String,
    pub entity_id: Uuid,
    #[serde(default)]
    pub entity_label: Option<String>,
    pub action: String,
    #[serde(default)]
    pub actor_user_id: Option<Uuid>,
    pub occurred_at: DateTime<Utc>,
}

impl TripActivityRow {
    pub fn into_model(self) -> trip_activity::Model {
        use crate::database::entities::trip_activity::TripActivityAction;
        let action = match self.action.as_str() {
            "insert" => TripActivityAction::Insert,
            "delete" => TripActivityAction::Delete,
            _ => TripActivityAction::Update,
        };
        trip_activity::Model {
            id: self.id,
            trip_id: self.trip_id,
            entity_type: self.entity_type,
            entity_id: self.entity_id,
            entity_label: self.entity_label,
            action,
            actor_user_id: self.actor_user_id,
            occurred_at: self.occurred_at,
        }
    }
}

// =====================================================================
// Day planner: trip_days + trip_day_locations + routes.
// =====================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TripDayRow {
    pub id: Uuid,
    pub trip_id: Uuid,
    pub date: chrono::NaiveDate,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub title: Option<String>,
    pub updated_at: DateTime<Utc>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub deleted_at: Option<DateTime<Utc>>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub last_modified_by: Option<Uuid>,
}

impl TripDayRow {
    pub fn from_model(m: &trip_day::Model) -> Self {
        Self {
            id: m.id,
            trip_id: m.trip_id,
            date: m.date,
            title: m.title.clone(),
            updated_at: m.updated_at,
            deleted_at: m.deleted_at,
            last_modified_by: parse_uuid_opt(m.last_modified_by.as_deref()),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TripDayLocationRow {
    pub trip_day_id: Uuid,
    pub location_id: Uuid,
    pub is_primary: bool,
    pub display_order: i32,
    pub updated_at: DateTime<Utc>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub deleted_at: Option<DateTime<Utc>>,
}

impl TripDayLocationRow {
    pub fn from_model(m: &trip_day_location::Model) -> Self {
        Self {
            trip_day_id: m.trip_day_id,
            location_id: m.location_id,
            is_primary: m.is_primary,
            display_order: m.display_order,
            updated_at: m.updated_at,
            deleted_at: m.deleted_at,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RouteRow {
    pub id: Uuid,
    pub trip_id: Uuid,
    pub provider: String,
    pub provider_route_id: String,
    pub name: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub sport: Option<String>,
    pub distance_meters: f64,
    pub duration_seconds: i64,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub elevation_up_meters: Option<f64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub elevation_down_meters: Option<f64>,
    pub start_latitude: f64,
    pub start_longitude: f64,
    pub polyline: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,
    pub external_url: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub trip_day_id: Option<Uuid>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub day_order: Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub scheduled_at: Option<DateTime<Utc>>,
    pub updated_at: DateTime<Utc>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub deleted_at: Option<DateTime<Utc>>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub last_modified_by: Option<Uuid>,
}

impl RouteRow {
    pub fn from_model(m: &route::Model) -> Self {
        let provider = match m.provider {
            RouteProvider::Komoot => "komoot".to_string(),
        };
        Self {
            id: m.id,
            trip_id: m.trip_id,
            provider,
            provider_route_id: m.provider_route_id.clone(),
            name: m.name.clone(),
            sport: m.sport.clone(),
            distance_meters: m.distance_meters,
            duration_seconds: m.duration_seconds,
            elevation_up_meters: m.elevation_up_meters,
            elevation_down_meters: m.elevation_down_meters,
            start_latitude: m.start_latitude,
            start_longitude: m.start_longitude,
            polyline: m.polyline.clone(),
            note: m.note.clone(),
            external_url: m.external_url.clone(),
            trip_day_id: m.trip_day_id,
            day_order: m.day_order,
            scheduled_at: m.scheduled_at,
            updated_at: m.updated_at,
            deleted_at: m.deleted_at,
            last_modified_by: parse_uuid_opt(m.last_modified_by.as_deref()),
        }
    }
}

pub fn parse_route_provider(s: &str) -> RouteProvider {
    match s {
        "komoot" => RouteProvider::Komoot,
        _ => RouteProvider::Komoot,
    }
}
