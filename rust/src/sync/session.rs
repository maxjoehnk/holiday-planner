use std::time::Duration;

use tokio::sync::RwLock;
use uuid::Uuid;

use crate::api::sync::SyncStatus;
use crate::database::Database;
use super::{backfill, coordinator, push, status};

/// Max time we wait for the outbox to drain on sign-out before
/// giving up and wiping the queue anyway.
/// Wait this long for the outbox to drain on sign-out before we
/// give up and wipe the queue. Sized larger than a single PostgREST
/// request timeout (30 s) is overkill; sized at 20 s gives a typical
/// 10-mutation batch room to land on a slow mobile network while
/// still keeping sign-out responsive. We emit `SyncStatus::Syncing`
/// during the drain so the UI can render a hint.
const FINAL_DRAIN_TIMEOUT: Duration = Duration::from_secs(20);

/// Cached Database handle so we can (re)start the coordinator on sign-in
/// without threading it through every API call.
static DB_HANDLE: RwLock<Option<Database>> = RwLock::const_new(None);

pub async fn set_db(db: Database) {
    *DB_HANDLE.write().await = Some(db);
}

/// Project URL (e.g. https://xyz.supabase.co). All PostgREST + Storage
/// traffic is dispatched from [`super::http`] using this URL and the
/// cached [`ACCESS_TOKEN`]; realtime uses [`super::realtime`].
static SUPABASE_URL: RwLock<Option<String>> = RwLock::const_new(None);
static SUPABASE_ANON_KEY: RwLock<Option<String>> = RwLock::const_new(None);

/// The currently signed-in user, if any. Set by [`set_auth_session`] and
/// cleared by [`clear_auth_session`].
static CURRENT_USER: RwLock<Option<Uuid>> = RwLock::const_new(None);

/// Cached access token. Read by [`super::http`] on every HTTP request so
/// PostgREST sees `auth.uid()` rather than the anonymous role.
static ACCESS_TOKEN: RwLock<Option<String>> = RwLock::const_new(None);

/// Cache the project URL + anon key. Called once at app startup with
/// values from `--dart-define` (or equivalent). Safe to call again to
/// switch projects.
pub async fn configure(url: String, anon_key: String) -> anyhow::Result<()> {
    *SUPABASE_URL.write().await = Some(url);
    *SUPABASE_ANON_KEY.write().await = Some(anon_key);
    status::emit(SyncStatus::SignedOut);
    Ok(())
}

/// Cache the signed-in user's JWT.
///
/// Dart owns the magic-link flow; on every `onAuthStateChange` event it
/// calls this function. `super::http` reads [`ACCESS_TOKEN`] on every
/// PostgREST / Storage request and `super::realtime` reads it on
/// connect / heartbeat-tick refresh.
pub async fn set_auth_session(access_token: String, user_id: Uuid) -> anyhow::Result<()> {
    *ACCESS_TOKEN.write().await = Some(access_token);
    *CURRENT_USER.write().await = Some(user_id);
    status::emit(SyncStatus::Idle);
    // Claim any local-only tags (created while anonymous, never put on a
    // trip) for the signed-in user before we kick the worker — otherwise
    // they'd stay invisible to other devices forever. Failure is
    // non-fatal; sync still functions.
    if let Some(db) = DB_HANDLE.read().await.clone() {
        if let Err(e) = backfill::claim_local_tags(&db).await {
            tracing::warn!("claim_local_tags on sign-in: {e:#}");
        }
    }
    // Drain anything queued while signed out.
    push::signal_pending();
    // Bring up the realtime coordinator (pull-then-subscribe).
    if let Some(db) = DB_HANDLE.read().await.clone() {
        coordinator::start(db).await;
    }
    Ok(())
}

/// Sign out: drop the token and forget who was signed in.
///
/// Before clearing anything we attempt one last drain of the outbox so
/// locally-pending edits actually land on the server. The drain runs
/// against the still-valid token — if it doesn't finish inside
/// [`FINAL_DRAIN_TIMEOUT`] we move on anyway. After that we wipe the
/// queue: leaving mutations behind would invite the next sign-in
/// (especially as a different user) to push every one of them under a
/// foreign RLS context, dead-lettering each.
pub async fn clear_auth_session() -> anyhow::Result<()> {
    if let Some(db) = DB_HANDLE.read().await.clone() {
        status::emit(SyncStatus::Syncing);
        let _ = tokio::time::timeout(FINAL_DRAIN_TIMEOUT, push::drain_now(&db)).await;
        if let Err(e) = push::clear_queue(&db).await {
            tracing::warn!("clear_queue on sign-out: {e:#}");
        }
    }

    // Stop the coordinator + push worker before clearing the token so
    // neither makes one last unauthenticated request on the way out.
    // `stop_worker` also resets WORKER_STARTED so a future spawn picks
    // up the (possibly rebound) DB handle.
    coordinator::stop().await;
    push::stop_worker().await;
    *ACCESS_TOKEN.write().await = None;
    *CURRENT_USER.write().await = None;
    status::emit(SyncStatus::SignedOut);
    Ok(())
}

pub async fn current_user() -> Option<Uuid> {
    *CURRENT_USER.read().await
}

pub async fn access_token() -> Option<String> {
    ACCESS_TOKEN.read().await.clone()
}

pub async fn supabase_url() -> Option<String> {
    SUPABASE_URL.read().await.clone()
}

pub async fn anon_key() -> Option<String> {
    SUPABASE_ANON_KEY.read().await.clone()
}
