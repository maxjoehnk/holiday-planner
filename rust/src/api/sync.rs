use std::ops::Deref;

use sea_orm::ActiveValue::Set;
use sea_orm::EntityTrait;
use tokio::sync::broadcast;
use uuid::Uuid;

use super::events::{self, DataChangeEvent};
use super::DB;
use crate::database::entities::profile::{self, Entity as Profile};
use crate::frb_generated::StreamSink;
use crate::sync::{self as sync_mod, backfill, http, session, status};

#[derive(Clone, Debug)]
pub enum SyncStatus {
    /// No user is signed in; sync is dormant.
    SignedOut,
    /// Signed in, sync is configured but no transport is active yet.
    Idle,
    /// Bringing the realtime channel up.
    Connecting,
    /// Realtime is live; changes flow both directions.
    Live,
    /// A push/pull batch is in flight.
    Syncing,
    /// We lost network or the WS dropped; the worker will reconnect.
    Offline,
    /// Non-recoverable error surface for the UI; the message is human-readable.
    Error { message: String },
}

#[derive(Clone, Debug)]
pub struct AuthSession {
    pub access_token: String,
    pub refresh_token: String,
    pub user_id: String,
    pub expires_at_unix_seconds: i64,
}

/// Configure the Supabase client. Called once at app startup with the
/// project URL and anon key (typically passed via `--dart-define`).
pub async fn configure_sync(url: String, anon_key: String) -> anyhow::Result<()> {
    session::configure(url, anon_key).await
}

/// Push the current auth session into Rust. Dart calls this on every
/// `onAuthStateChange` after `supabase_flutter` signs in / refreshes the
/// JWT. Pass `None` to sign out.
pub async fn set_auth_session(session: Option<AuthSession>) -> anyhow::Result<()> {
    match session {
        Some(s) => {
            let user_id = Uuid::parse_str(&s.user_id)?;
            session::set_auth_session(s.access_token, user_id).await
        }
        None => session::clear_auth_session().await,
    }
}

/// How many local trips were created while anonymous and haven't been
/// pushed yet. Drives the "Upload N trips" button on the sync sheet.
pub async fn local_only_trip_count() -> anyhow::Result<u64> {
    let db = DB.read().await;
    let Some(db) = db.as_ref() else {
        return Ok(0);
    };
    backfill::count_local_only_trips(db).await
}

/// Claim every anonymous trip for the signed-in user and enqueue its
/// full subtree for push. Returns the number of trips queued.
pub async fn upload_local_only_trips() -> anyhow::Result<u64> {
    let db = DB.read().await;
    let db = db.as_ref().ok_or_else(|| anyhow::anyhow!("Database not connected"))?;
    let count = backfill::upload_local_only_trips(db).await?;
    if count > 0 {
        events::emit(DataChangeEvent::TripsChanged);
    }
    Ok(count)
}

/// Claim a single trip for the signed-in user and enqueue its subtree.
/// Used by the per-card "sync this trip" button on the trip list.
#[tracing::instrument]
pub async fn upload_trip(trip_id: Uuid) -> anyhow::Result<()> {
    let db = DB.read().await;
    let db = db.as_ref().ok_or_else(|| anyhow::anyhow!("Database not connected"))?;
    backfill::upload_trip(db, trip_id).await?;
    // Refresh the trip card so its sync chip flips from "upload" to
    // "synced" right away; without this nothing tells the list to refetch.
    events::emit(DataChangeEvent::TripsChanged);
    events::emit(DataChangeEvent::TripChanged { trip_id });
    Ok(())
}

/// Snapshot of the signed-in user's profile row used by the account
/// screen. Returned by [`get_my_profile`].
#[derive(Clone, Debug)]
pub struct MyProfile {
    pub user_id: Uuid,
    pub email: String,
    pub display_name: Option<String>,
}

/// Read the current user's profile row from local SQLite. Returns
/// `None` if the user is signed out OR if the profile pull hasn't
/// brought their row down yet (rare race on first sign-in).
pub async fn get_my_profile() -> anyhow::Result<Option<MyProfile>> {
    let Some(user_id) = session::current_user().await else {
        return Ok(None);
    };
    let db_guard = DB.read().await;
    let Some(db) = db_guard.as_ref() else {
        return Ok(None);
    };
    let row = Profile::find_by_id(user_id).one(db.deref()).await?;
    Ok(row.map(|r| MyProfile {
        user_id: r.id,
        email: r.email,
        display_name: r.display_name,
    }))
}

/// Update the user's display name. The trimmed value is pushed straight
/// to PostgREST (RLS scopes writes to the caller's own row) and then
/// applied locally so the UI doesn't have to wait for a pull. An
/// empty / whitespace-only string clears the name.
pub async fn update_my_profile(display_name: Option<String>) -> anyhow::Result<()> {
    let user_id = session::current_user()
        .await
        .ok_or_else(|| anyhow::anyhow!("Not signed in"))?;
    let trimmed: Option<String> = display_name.and_then(|s| {
        let t = s.trim().to_string();
        if t.is_empty() { None } else { Some(t) }
    });
    let now = chrono::Utc::now();
    let patch = serde_json::json!({
        "display_name": trimmed.as_deref(),
        "updated_at": now,
    });
    http::patch_by_id("profiles", &user_id.to_string(), &patch).await?;

    // Optimistic local apply. The row may not exist locally yet on a
    // very-first sign-in — in that case the pending pull request below
    // will fetch it.
    if let Some(db) = DB.read().await.as_ref() {
        let active = profile::ActiveModel {
            id: Set(user_id),
            display_name: Set(trimmed.clone()),
            updated_at: Set(now),
            ..Default::default()
        };
        let _ = Profile::update(active).exec(db.deref()).await;
    }
    sync_mod::coordinator::request_pull();
    Ok(())
}

/// Delete the signed-in user's account: wipe the server-side data
/// (via the `delete_my_account` RPC) and unlink every local trip so
/// they live on as anonymous local-only data.
#[tracing::instrument]
pub async fn delete_account() -> anyhow::Result<()> {
    // 1. Server first — if it fails we want the user to retry with
    //    their state intact rather than losing the local linkage.
    crate::sync::http::rpc("delete_my_account", &serde_json::json!({})).await?;

    // 2. Local wipe — drop every Supabase-tied artifact so the app
    //    can keep working anonymously.
    {
        let db_guard = DB.read().await;
        let db = db_guard
            .as_ref()
            .ok_or_else(|| anyhow::anyhow!("Database not connected"))?;
        let conn = std::ops::Deref::deref(db);
        use sea_orm::ConnectionTrait;
        conn.execute_unprepared(
            r#"
            UPDATE trips SET owner_id = NULL, detached_at = NULL, last_modified_by = NULL;
            DELETE FROM trip_members;
            DELETE FROM profiles;
            DELETE FROM pending_mutations;
            DELETE FROM sync_cursors;
            DELETE FROM trip_activity;
            "#,
        )
        .await?;
    }

    // 3. Sign out — clears the JWT, stops the coordinator, and lets
    //    the auth bus broadcast SignedOut so the UI updates.
    crate::sync::session::clear_auth_session().await?;

    events::emit(DataChangeEvent::TripsChanged);
    Ok(())
}

/// Stream of [`SyncStatus`] updates for the UI. Mirrors the pattern used
/// by `subscribe_data_changes`.
pub async fn sync_status_stream(sink: StreamSink<SyncStatus>) -> anyhow::Result<()> {
    let mut receiver = status::subscribe();
    tokio::spawn(async move {
        loop {
            match receiver.recv().await {
                Ok(status) => {
                    if sink.add(status).is_err() {
                        break;
                    }
                }
                Err(broadcast::error::RecvError::Lagged(skipped)) => {
                    tracing::warn!("Sync status subscriber lagged, skipped {} events", skipped);
                    continue;
                }
                Err(broadcast::error::RecvError::Closed) => break,
            }
        }
    });
    Ok(())
}
