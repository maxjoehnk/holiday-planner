//! Per-trip activity feed.
//!
//! Reads from the `trip_activity` table — an append-only log populated
//! server-side by AFTER triggers on each trip-scoped table. Clients
//! pull and display; they never write.

use std::collections::HashMap;
use std::ops::Deref;

use chrono::{DateTime, Utc};
use sea_orm::{ColumnTrait, EntityTrait, QueryFilter, QueryOrder, QuerySelect};
use uuid::Uuid;

use crate::database::entities::profile::{self, Entity as Profile};
use crate::database::entities::trip_activity::{
    self, Entity as TripActivity, TripActivityAction,
};
use crate::database::Database;
use crate::handlers::Handler;

pub struct ActivityHandler {
    db: Database,
}

impl Handler for ActivityHandler {
    fn create(db: Database) -> Self {
        Self { db }
    }
}

#[derive(Debug, Clone)]
pub struct ActivityEntry {
    pub entity_kind: ActivityEntityKind,
    pub entity_id: Uuid,
    pub entity_label: Option<String>,
    pub action: ActivityAction,
    pub occurred_at: DateTime<Utc>,
    pub user_id: Option<Uuid>,
    pub user_email: Option<String>,
    pub user_display_name: Option<String>,
}

#[derive(Debug, Clone, Copy)]
pub enum ActivityEntityKind {
    Trip,
    Accommodation,
    Location,
    Reservation,
    CarRental,
    PointOfInterest,
    Train,
    Other,
}

#[derive(Debug, Clone, Copy)]
pub enum ActivityAction {
    Insert,
    Update,
    Delete,
}

impl From<TripActivityAction> for ActivityAction {
    fn from(value: TripActivityAction) -> Self {
        match value {
            TripActivityAction::Insert => ActivityAction::Insert,
            TripActivityAction::Update => ActivityAction::Update,
            TripActivityAction::Delete => ActivityAction::Delete,
        }
    }
}

impl ActivityHandler {
    pub async fn list_trip_activity(
        &self,
        trip_id: Uuid,
        limit: u32,
    ) -> anyhow::Result<Vec<ActivityEntry>> {
        let conn = self.db.deref();
        let rows = TripActivity::find()
            .filter(trip_activity::Column::TripId.eq(trip_id))
            .order_by_desc(trip_activity::Column::OccurredAt)
            .limit(limit.max(1) as u64)
            .all(conn)
            .await?;

        let user_ids: Vec<Uuid> = rows.iter().filter_map(|r| r.actor_user_id).collect();
        let profiles: HashMap<Uuid, profile::Model> = if user_ids.is_empty() {
            HashMap::new()
        } else {
            Profile::find()
                .filter(profile::Column::Id.is_in(user_ids))
                .all(conn)
                .await?
                .into_iter()
                .map(|p| (p.id, p))
                .collect()
        };

        Ok(rows
            .into_iter()
            .map(|row| {
                let kind = entity_kind_from_table(&row.entity_type);
                let profile = row.actor_user_id.and_then(|u| profiles.get(&u));
                ActivityEntry {
                    entity_kind: kind,
                    entity_id: row.entity_id,
                    entity_label: row.entity_label,
                    action: row.action.into(),
                    occurred_at: row.occurred_at,
                    user_id: row.actor_user_id,
                    user_email: profile.map(|p| p.email.clone()),
                    user_display_name: profile.and_then(|p| p.display_name.clone()),
                }
            })
            .collect())
    }
}

fn entity_kind_from_table(table: &str) -> ActivityEntityKind {
    match table {
        "trips" => ActivityEntityKind::Trip,
        "accommodations" => ActivityEntityKind::Accommodation,
        "locations" => ActivityEntityKind::Location,
        "reservations" => ActivityEntityKind::Reservation,
        "car_rentals" => ActivityEntityKind::CarRental,
        "points_of_interest" => ActivityEntityKind::PointOfInterest,
        "trains" => ActivityEntityKind::Train,
        _ => ActivityEntityKind::Other,
    }
}
