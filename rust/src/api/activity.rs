use chrono::{DateTime, Utc};
use uuid::Uuid;

use super::DB;
use crate::handlers::{
    ActivityAction, ActivityEntityKind, ActivityHandler, HandlerCreator,
};

#[derive(Clone, Debug)]
pub enum TripActivityKind {
    Trip,
    Accommodation,
    Location,
    Reservation,
    CarRental,
    PointOfInterest,
    Train,
    Other,
}

#[derive(Clone, Debug)]
pub enum TripActivityAction {
    Insert,
    Update,
    Delete,
}

impl From<ActivityEntityKind> for TripActivityKind {
    fn from(value: ActivityEntityKind) -> Self {
        match value {
            ActivityEntityKind::Trip => TripActivityKind::Trip,
            ActivityEntityKind::Accommodation => TripActivityKind::Accommodation,
            ActivityEntityKind::Location => TripActivityKind::Location,
            ActivityEntityKind::Reservation => TripActivityKind::Reservation,
            ActivityEntityKind::CarRental => TripActivityKind::CarRental,
            ActivityEntityKind::PointOfInterest => TripActivityKind::PointOfInterest,
            ActivityEntityKind::Train => TripActivityKind::Train,
            ActivityEntityKind::Other => TripActivityKind::Other,
        }
    }
}

impl From<ActivityAction> for TripActivityAction {
    fn from(value: ActivityAction) -> Self {
        match value {
            ActivityAction::Insert => TripActivityAction::Insert,
            ActivityAction::Update => TripActivityAction::Update,
            ActivityAction::Delete => TripActivityAction::Delete,
        }
    }
}

#[derive(Clone, Debug)]
pub struct TripActivityEntry {
    pub kind: TripActivityKind,
    pub entity_id: Uuid,
    pub label: Option<String>,
    pub action: TripActivityAction,
    pub occurred_at: DateTime<Utc>,
    pub user_id: Option<Uuid>,
    pub user_email: Option<String>,
    pub user_display_name: Option<String>,
}

/// Return the most recent activity log entries for a trip, joined with
/// profile info for the actor. `limit` defaults to 50 if 0 is passed.
#[tracing::instrument]
pub async fn list_trip_activity(
    trip_id: Uuid,
    limit: u32,
) -> anyhow::Result<Vec<TripActivityEntry>> {
    let handler = DB.try_get::<ActivityHandler>().await?;
    let limit = if limit == 0 { 50 } else { limit };
    let entries = handler.list_trip_activity(trip_id, limit).await?;
    Ok(entries
        .into_iter()
        .map(|e| TripActivityEntry {
            kind: e.entity_kind.into(),
            entity_id: e.entity_id,
            label: e.entity_label,
            action: e.action.into(),
            occurred_at: e.occurred_at,
            user_id: e.user_id,
            user_email: e.user_email,
            user_display_name: e.user_display_name,
        })
        .collect())
}
