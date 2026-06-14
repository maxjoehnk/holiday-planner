//! Push pipeline: drain `pending_mutations` to Supabase.
//!
//! Each mutation gets one PostgREST call (upsert or soft-delete update).
//! Successful pushes delete the queue row. Failures bump `attempts` and
//! emit a [`SyncStatus::Error`]; the worker backs off and retries on the
//! next notify.

use std::ops::Deref;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::OnceLock;
use std::time::Duration;

use sea_orm::ActiveValue::Set;
use sea_orm::{ColumnTrait, ConnectionTrait, EntityTrait, QueryFilter, QueryOrder, QuerySelect};
use serde::Serialize;
use serde_json::Value as JsonValue;
use tokio::sync::Notify;
use uuid::Uuid;

use crate::api::sync::SyncStatus;
use crate::database::entities::pending_mutation::{
    self, ActiveModel as PendingMutationActive, Entity as PendingMutation, MutationOperation,
};
use crate::database::Database;
use crate::sync::{http, session, status};

const BATCH_SIZE: u64 = 20;
const RETRY_BACKOFF: Duration = Duration::from_secs(5);
/// After this many consecutive failures a mutation stops being retried.
/// The row stays in `pending_mutations` with `last_error` set so it can be
/// inspected; the queue filters it out of future drains.
const MAX_ATTEMPTS: i32 = 10;
/// If this many mutations fail in a row inside a single drain we assume a
/// systemic problem (network down, JWT expired) and stop early. The retry
/// tick will re-attempt later instead of burning through the whole batch.
const MAX_CONSECUTIVE_FAILURES: u32 = 3;

static PUSH_NOTIFY: OnceLock<Notify> = OnceLock::new();
static WORKER_STARTED: AtomicBool = AtomicBool::new(false);

fn notify() -> &'static Notify {
    PUSH_NOTIFY.get_or_init(Notify::new)
}

/// Wake the drain worker. Idempotent: extra calls just coalesce.
pub fn signal_pending() {
    notify().notify_one();
}

/// Enqueue a mutation only if a user is signed in (anonymous mode skips
/// the outbox entirely). Use this from handlers; the lower-level
/// [`enqueue`] is for internal sync use.
pub async fn enqueue_if_signed_in<T: Serialize>(
    db: &Database,
    entity_type: &str,
    entity_id: Uuid,
    operation: MutationOperation,
    payload: &T,
) -> anyhow::Result<()> {
    if session::current_user().await.is_none() {
        return Ok(());
    }
    enqueue(db.deref(), entity_type, entity_id, operation, payload).await
}

/// Enqueue a mutation in the local outbox. Must be called from the same
/// SQLite transaction (or at least the same connection) as the actual
/// data write so a crash never leaves the two out of sync.
pub async fn enqueue<T: Serialize>(
    conn: &impl ConnectionTrait,
    entity_type: &str,
    entity_id: Uuid,
    operation: MutationOperation,
    payload: &T,
) -> anyhow::Result<()> {
    let payload_json = serde_json::to_string(payload)?;
    let row = PendingMutationActive {
        entity_type: Set(entity_type.to_string()),
        entity_id: Set(entity_id),
        operation: Set(operation),
        payload: Set(payload_json),
        ..Default::default()
    };
    PendingMutation::insert(row)
        .exec_without_returning(conn)
        .await?;
    signal_pending();
    Ok(())
}

/// Spawn the drain loop. Idempotent — extra calls are no-ops so a stray
/// re-invocation (token refresh, hot restart) can never spawn a second
/// worker that would race the first one on the same queue rows.
pub fn spawn_worker(db: Database) {
    if WORKER_STARTED.swap(true, Ordering::SeqCst) {
        return;
    }
    tokio::spawn(async move {
        loop {
            // Wait for an enqueue signal OR a periodic retry tick.
            tokio::select! {
                _ = notify().notified() => {},
                _ = tokio::time::sleep(RETRY_BACKOFF) => {},
            }
            if session::current_user().await.is_none() {
                continue;
            }
            match drain(&db).await {
                Ok(drained) if drained > 0 => {
                    tracing::debug!("Pushed {drained} mutation(s)");
                    status::emit(SyncStatus::Idle);
                }
                Ok(_) => {}
                Err(e) => {
                    tracing::warn!("Push drain failed: {e:#}");
                    status::emit(SyncStatus::Error { message: e.to_string() });
                }
            }
        }
    });
}

/// Run a single drain pass synchronously. Used by sign-out to give
/// pending mutations one last chance to reach the server before the
/// session token is cleared.
pub async fn drain_now(db: &Database) -> anyhow::Result<usize> {
    drain(db).await
}

/// Wipe every queued mutation. Called on sign-out so a subsequent
/// sign-in (especially as a different user) doesn't drain mutations
/// attributed to the prior session and dead-letter every one of them
/// under the new user's RLS context.
pub async fn clear_queue(db: &Database) -> anyhow::Result<()> {
    PendingMutation::delete_many().exec(db.deref()).await?;
    Ok(())
}

async fn drain(db: &Database) -> anyhow::Result<usize> {
    let mut total = 0usize;
    let mut consecutive_failures: u32 = 0;
    loop {
        // Skip dead-lettered mutations so one permanently broken row can
        // never block the rest of the queue.
        let pending = PendingMutation::find()
            .filter(pending_mutation::Column::Attempts.lt(MAX_ATTEMPTS))
            .order_by_asc(pending_mutation::Column::CreatedAt)
            .limit(BATCH_SIZE)
            .all(db.deref())
            .await?;
        if pending.is_empty() {
            break;
        }
        if total == 0 {
            status::emit(SyncStatus::Syncing);
        }
        for mutation in pending {
            match push_one(db, &mutation).await {
                Ok(()) => {
                    PendingMutation::delete_by_id(mutation.id)
                        .exec(db.deref())
                        .await?;
                    total += 1;
                    consecutive_failures = 0;
                }
                Err(e) => {
                    let attempts = mutation.attempts.saturating_add(1);
                    tracing::warn!(
                        "push {} {} failed (attempt {attempts}/{MAX_ATTEMPTS}): {e:#}",
                        mutation.entity_type,
                        mutation.entity_id,
                    );
                    record_failure(db, &mutation, &e, attempts).await?;
                    status::emit(SyncStatus::Error { message: format!("{e:#}") });
                    if attempts >= MAX_ATTEMPTS {
                        tracing::error!(
                            "push {} {} dead-lettered after {attempts} attempts",
                            mutation.entity_type,
                            mutation.entity_id,
                        );
                    }
                    consecutive_failures += 1;
                    if consecutive_failures >= MAX_CONSECUTIVE_FAILURES {
                        return Ok(total);
                    }
                }
            }
        }
    }
    Ok(total)
}

async fn record_failure(
    db: &Database,
    mutation: &pending_mutation::Model,
    error: &anyhow::Error,
    attempts: i32,
) -> anyhow::Result<()> {
    let active = pending_mutation::ActiveModel {
        id: Set(mutation.id),
        attempts: Set(attempts),
        last_error: Set(Some(format!("{error:#}"))),
        ..Default::default()
    };
    PendingMutation::update(active).exec(db.deref()).await?;
    Ok(())
}

async fn push_one(
    db: &Database,
    mutation: &pending_mutation::Model,
) -> anyhow::Result<()> {
    let table = mutation.entity_type.as_str();
    match mutation.operation {
        // Insert and Update both flow through a conditional PATCH +
        // INSERT-fallback pattern. We can't use a plain upsert: if the
        // server has soft-deleted the row, an unconditional upsert would
        // overwrite the tombstone and resurrect the row on every device
        // on the next pull. Conditional PATCH (filtered on
        // `deleted_at=is.null`) silently no-ops on tombstoned rows; the
        // INSERT fallback covers the genuinely-new case.
        MutationOperation::Insert | MutationOperation::Update => {
            // Attachments need their blob uploaded to Storage *before* the
            // metadata row references its `storage_path` — otherwise other
            // devices would see the row and fail to download the bytes.
            if table == "attachments" {
                upload_attachment_blob_if_needed(db, mutation.entity_id).await?;
            }
            // Same idea for trip header images. The bytes only ride in
            // the local row; the wire format carries just the path +
            // hash + uploaded_at, so the blob has to land first.
            if table == "trips" {
                upload_trip_header_if_needed(db, mutation.entity_id).await?;
            }
            // Rebuild the payload from the current local row so the queue
            // can never serve stale or corrupted JSON. Fall back to the
            // stored payload only for tables we don't have a per-row
            // refresh path for.
            let payload = match refresh_payload(db, table, mutation.entity_id).await? {
                Some(fresh) => fresh,
                None => serde_json::from_str(&mutation.payload)?,
            };
            if table == "tags" || table == "user_tags" {
                // Tags and user_tags are append-only with deterministic
                // / composite primary keys. An INSERT either creates
                // the row or hits the unique constraint because another
                // path already inserted it — both outcomes mean the
                // canonical row exists, so drop the mutation silently
                // in the duplicate case.
                let _ = http::insert(table, &payload).await?;
            } else {
                let filter = alive_filter(table, mutation.entity_id, &payload)?;
                let updated = http::patch_query_returning(&filter, &payload).await?;
                if updated == 0 {
                    // Either the row doesn't exist yet, or it exists but
                    // is tombstoned. An INSERT distinguishes the two —
                    // duplicate PK means the server has a tombstone, in
                    // which case the tombstone wins (the local row will
                    // be cleaned up on the next pull) and the mutation
                    // is dropped.
                    let created = http::insert(table, &payload).await?;
                    if !created {
                        tracing::warn!(
                            "push {table} {}: server row is tombstoned, dropping non-delete mutation",
                            mutation.entity_id,
                        );
                    }
                }
            }
        }
        MutationOperation::Delete if is_join_table(table) => {
            // Composite-PK soft delete; the payload carries the column pair.
            let payload: JsonValue = serde_json::from_str(&mutation.payload)?;
            let now = chrono::Utc::now();
            let patch = serde_json::json!({
                "deleted_at": now,
                "updated_at": now,
            });
            let query = build_join_filter(table, &payload)?;
            http::patch_by_query(&query, &patch).await?;
        }
        MutationOperation::Delete => {
            // Trip owners hard-delete the row (cascades clean up every
            // child + trip_members / activity). The cascade does NOT
            // touch Storage objects, so we scrub the bucket first using
            // the storage_paths snapshot the handler captured.
            if table == "trips" {
                if let Ok(payload) = serde_json::from_str::<JsonValue>(&mutation.payload) {
                    if payload.get("hard_delete").and_then(|v| v.as_bool()).unwrap_or(false) {
                        if let Some(paths) =
                            payload.get("storage_paths").and_then(|v| v.as_array())
                        {
                            for p in paths {
                                if let Some(path) = p.as_str() {
                                    if !path.is_empty() {
                                        if let Err(e) = http::storage_delete(
                                            crate::sync::wire::ATTACHMENTS_BUCKET,
                                            path,
                                        )
                                        .await
                                        {
                                            tracing::warn!(
                                                "storage scrub {path}: {e:#}"
                                            );
                                        }
                                    }
                                }
                            }
                        }
                        http::delete_by_id(table, &mutation.entity_id.to_string()).await?;
                        return Ok(());
                    }
                }
            }
            // For attachments, scrub the Storage object on the way out.
            // The blob can disappear before the row tombstone lands; missing
            // objects are tolerated by `storage_delete`.
            if table == "attachments" {
                if let Ok(payload) = serde_json::from_str::<JsonValue>(&mutation.payload) {
                    if let Some(path) = payload.get("storage_path").and_then(|v| v.as_str()) {
                        if !path.is_empty() {
                            if let Err(e) = http::storage_delete(
                                crate::sync::wire::ATTACHMENTS_BUCKET,
                                path,
                            )
                            .await
                            {
                                tracing::warn!("storage delete {path}: {e:#}");
                            }
                        }
                    }
                }
            }
            // Soft delete on the wire so realtime can broadcast the
            // tombstone. The local row was already hard-deleted.
            let now = chrono::Utc::now();
            let patch = serde_json::json!({
                "deleted_at": now,
                "updated_at": now,
            });
            http::patch_by_id(table, &mutation.entity_id.to_string(), &patch).await?;
        }
    }
    Ok(())
}

/// Rebuild the push payload from the current local row. Returns `None`
/// for tables/rows we don't recognise (caller will fall back to the
/// stored payload from the queue).
async fn refresh_payload(
    db: &Database,
    table: &str,
    id: Uuid,
) -> anyhow::Result<Option<JsonValue>> {
    use crate::database::entities::{
        accommodation::Entity as Accommodation, attachment::Entity as Attachment,
        car_rental::Entity as CarRental, location::Entity as Location,
        point_of_interest::Entity as PointOfInterest, reservation::Entity as Reservation,
        tag::Entity as Tag, train::Entity as Train, trip::Entity as Trip,
    };
    use crate::sync::wire;
    use sea_orm::EntityTrait;

    let conn = db.deref();
    let payload = match table {
        "trips" => {
            let Some(m) = Trip::find_by_id(id).one(conn).await? else { return Ok(None) };
            let owner = m
                .owner_id
                .as_deref()
                .and_then(|s| Uuid::parse_str(s).ok());
            let Some(owner) = owner else { return Ok(None) };
            serde_json::to_value(wire::TripRow::from_model(&m, owner))?
        }
        "accommodations" => {
            let Some(m) = Accommodation::find_by_id(id).one(conn).await? else { return Ok(None) };
            serde_json::to_value(wire::AccommodationRow::from_model(&m))?
        }
        "locations" => {
            let Some(m) = Location::find_by_id(id).one(conn).await? else { return Ok(None) };
            serde_json::to_value(wire::LocationRow::from_model(&m))?
        }
        "car_rentals" => {
            let Some(m) = CarRental::find_by_id(id).one(conn).await? else { return Ok(None) };
            serde_json::to_value(wire::CarRentalRow::from_model(&m))?
        }
        "reservations" => {
            let Some(m) = Reservation::find_by_id(id).one(conn).await? else { return Ok(None) };
            serde_json::to_value(wire::ReservationRow::from_model(&m))?
        }
        "points_of_interest" => {
            let Some(m) = PointOfInterest::find_by_id(id).one(conn).await? else { return Ok(None) };
            serde_json::to_value(wire::PointOfInterestRow::from_model(&m))?
        }
        "trains" => {
            let Some(m) = Train::find_by_id(id).one(conn).await? else { return Ok(None) };
            serde_json::to_value(wire::TrainRow::from_model(&m))?
        }
        "tags" => {
            let Some(m) = Tag::find_by_id(id).one(conn).await? else { return Ok(None) };
            serde_json::to_value(wire::TagRow::from_model(&m))?
        }
        "attachments" => {
            let Some(m) = Attachment::find_by_id(id).one(conn).await? else { return Ok(None) };
            match wire::AttachmentRow::from_model(&m) {
                Some(row) => serde_json::to_value(row)?,
                None => return Ok(None),
            }
        }
        // Join tables key on (parent, child) and don't carry mutable state
        // beyond timestamps — the stored payload is still authoritative.
        _ => return Ok(None),
    };
    Ok(Some(payload))
}

/// Build a PostgREST URL query string that matches the row by its PK and
/// rejects soft-deleted rows. The push pipeline PATCHes against this
/// filter so a server-side tombstone silently swallows the update.
fn alive_filter(
    table: &str,
    entity_id: Uuid,
    payload: &JsonValue,
) -> anyhow::Result<String> {
    if is_join_table(table) {
        let mut q = build_join_filter(table, payload)?;
        q.push_str("&deleted_at=is.null");
        Ok(q)
    } else {
        Ok(format!("{table}?id=eq.{entity_id}&deleted_at=is.null"))
    }
}

fn is_join_table(table: &str) -> bool {
    matches!(
        table,
        "accommodation_attachments"
            | "location_attachments"
            | "trip_tags"
            | "trip_members"
            | "user_tags"
    )
}

/// Build a PostgREST query string for a join table soft-delete, derived
/// from the JSON payload's composite-key columns.
fn build_join_filter(table: &str, payload: &JsonValue) -> anyhow::Result<String> {
    let cols: &[&str] = match table {
        "accommodation_attachments" => &["accommodation_id", "attachment_id"],
        "location_attachments" => &["location_id", "attachment_id"],
        "trip_tags" => &["trip_id", "tag_id"],
        "trip_members" => &["trip_id", "user_id"],
        "user_tags" => &["user_id", "tag_id"],
        _ => anyhow::bail!("unsupported join table {table}"),
    };
    let mut q = format!("{table}?");
    for (i, col) in cols.iter().enumerate() {
        let v = payload
            .get(col)
            .and_then(|v| v.as_str())
            .ok_or_else(|| anyhow::anyhow!("payload missing {col}"))?;
        if i > 0 {
            q.push('&');
        }
        q.push_str(col);
        q.push_str("=eq.");
        q.push_str(v);
    }
    Ok(q)
}

/// Mirror of [`upload_attachment_blob_if_needed`] for trip header
/// images. Idempotent: if the row already has `header_image_uploaded_at`
/// set we skip the upload entirely.
async fn upload_trip_header_if_needed(
    db: &Database,
    trip_id: Uuid,
) -> anyhow::Result<()> {
    use crate::database::entities::trip::{self, Entity as Trip};
    use sea_orm::EntityTrait;

    let Some(model) = Trip::find_by_id(trip_id).one(db.deref()).await? else {
        return Ok(());
    };
    let (Some(path), Some(bytes)) = (model.header_image_path.clone(), model.header_image.clone())
    else {
        return Ok(());
    };
    if model.header_image_uploaded_at.is_some() {
        return Ok(());
    }

    http::storage_upload(
        crate::sync::wire::ATTACHMENTS_BUCKET,
        &path,
        "application/octet-stream",
        bytes,
    )
    .await?;

    let now = chrono::Utc::now();
    let active = trip::ActiveModel {
        id: Set(trip_id),
        header_image_uploaded_at: Set(Some(now)),
        ..Default::default()
    };
    Trip::update(active).exec(db.deref()).await?;
    Ok(())
}

/// Read the local attachment, upload its bytes to Storage if we haven't
/// pushed them before (or the bytes changed), then mark the local row as
/// `uploaded_at = now`. A failure here propagates up so the push worker
/// retries the whole mutation later.
async fn upload_attachment_blob_if_needed(
    db: &Database,
    attachment_id: Uuid,
) -> anyhow::Result<()> {
    use crate::database::repositories::attachments;
    let Some(model) = attachments::find_by_id(db, attachment_id).await? else {
        // The row was deleted underneath us — nothing to upload.
        return Ok(());
    };
    let Some(storage_path) = model.storage_path.clone() else {
        return Ok(());
    };
    if model.uploaded_at.is_some() {
        return Ok(());
    }
    let bytes = model.data.clone();
    let content_type = model.content_type.clone();
    http::storage_upload(
        crate::sync::wire::ATTACHMENTS_BUCKET,
        &storage_path,
        &content_type,
        bytes,
    )
    .await?;
    attachments::mark_uploaded(db.deref(), attachment_id, chrono::Utc::now()).await?;
    Ok(())
}
