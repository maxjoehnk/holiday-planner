//! PostgREST delta pull: fetch rows whose `updated_at` is newer than the
//! local cursor, apply them, then advance the cursor.

use std::ops::Deref;

use chrono::{DateTime, Utc};
use sea_orm::ActiveValue::Set;
use sea_orm::sea_query::OnConflict;
use sea_orm::EntityTrait;
use serde_json::Value;

use crate::database::entities::sync_cursor;
use crate::database::Database;
use crate::sync::{apply, http};

/// Tables the pull pipeline knows about. Mirrors the push allowlist —
/// grows as later steps wire more entities.
pub const SYNCED_TABLES: &[&str] = &[
    "trips",
    "accommodations",
    "locations",
    "car_rentals",
    "reservations",
    "points_of_interest",
    "trains",
    "tags",
    "user_tags",
    "attachments",
    "accommodation_attachments",
    "location_attachments",
    "trip_tags",
    "trip_members",
    "profiles",
    "trip_activity",
];

/// Most tables use `updated_at`; the activity log is append-only and
/// uses `occurred_at`.
fn cursor_column(table: &str) -> &'static str {
    match table {
        "trip_activity" => "occurred_at",
        _ => "updated_at",
    }
}

pub async fn pull_all(db: &Database) -> anyhow::Result<()> {
    for table in SYNCED_TABLES {
        pull_table(db, table).await?;
    }
    Ok(())
}

pub async fn pull_table(db: &Database, table: &str) -> anyhow::Result<()> {
    let col = cursor_column(table);
    let cursor_ms = get_cursor(db, table).await?;
    let cursor_iso = cursor_iso(cursor_ms);

    let rows: Vec<Value> = http::select_gt(table, col, &cursor_iso).await?;

    if rows.is_empty() {
        return Ok(());
    }

    tracing::debug!("pull {table}: {} new row(s) since {cursor_iso}", rows.len());

    let mut max_seen = cursor_ms;
    for row in rows {
        if let Some(ts) = row.get(col).and_then(|v| v.as_str()) {
            if let Ok(dt) = DateTime::parse_from_rfc3339(ts) {
                let ms = dt.timestamp_millis();
                if ms > max_seen {
                    max_seen = ms;
                }
            }
        }
        if let Err(e) = apply::apply_remote_row(db, table, row).await {
            // One bad row shouldn't poison the whole batch; log and continue.
            tracing::warn!("apply {table}: {e:#}");
        }
    }

    if max_seen > cursor_ms {
        set_cursor(db, table, max_seen).await?;
    }
    Ok(())
}

fn cursor_iso(ms: i64) -> String {
    DateTime::<Utc>::from_timestamp_millis(ms)
        .unwrap_or(DateTime::<Utc>::UNIX_EPOCH)
        .to_rfc3339()
}

async fn get_cursor(db: &Database, table: &str) -> anyhow::Result<i64> {
    let entry = sync_cursor::Entity::find_by_id(table.to_string())
        .one(db.deref())
        .await?;
    Ok(entry.map(|e| e.last_pulled_at).unwrap_or(0))
}

async fn set_cursor(db: &Database, table: &str, value: i64) -> anyhow::Result<()> {
    let model = sync_cursor::ActiveModel {
        entity_type: Set(table.to_string()),
        last_pulled_at: Set(value),
    };
    sync_cursor::Entity::insert(model)
        .on_conflict(
            OnConflict::column(sync_cursor::Column::EntityType)
                .update_column(sync_cursor::Column::LastPulledAt)
                .to_owned(),
        )
        .exec_without_returning(db.deref())
        .await?;
    Ok(())
}
