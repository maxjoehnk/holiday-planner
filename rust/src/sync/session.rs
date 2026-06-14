use std::sync::Arc;
use std::time::Duration;

use anyhow::anyhow;
use supabase::Client as SupabaseClient;
use tokio::sync::RwLock;
use uuid::Uuid;

use crate::api::sync::SyncStatus;
use crate::database::Database;
use super::{coordinator, push, status};

/// Max time we wait for the outbox to drain on sign-out before
/// giving up and wiping the queue anyway.
const FINAL_DRAIN_TIMEOUT: Duration = Duration::from_secs(5);

/// Cached Database handle so we can (re)start the coordinator on sign-in
/// without threading it through every API call.
static DB_HANDLE: RwLock<Option<Database>> = RwLock::const_new(None);

pub async fn set_db(db: Database) {
    *DB_HANDLE.write().await = Some(db);
}

/// Bound to the project URL + anon key. Cleared and rebuilt only if
/// [`configure`] is called again (rare; the user would have to switch
/// Supabase projects).
static CLIENT: RwLock<Option<Arc<SupabaseClient>>> = RwLock::const_new(None);

/// Project URL (e.g. https://xyz.supabase.co). Used for direct PostgREST
/// calls; `supabase-lib-rs`'s `set_auth` doesn't actually forward the JWT
/// to HTTP requests, so push / pull go via [`super::http`] instead.
static SUPABASE_URL: RwLock<Option<String>> = RwLock::const_new(None);
static SUPABASE_ANON_KEY: RwLock<Option<String>> = RwLock::const_new(None);

/// The currently signed-in user, if any. Set by [`set_auth_session`] and
/// cleared by [`clear_auth_session`].
static CURRENT_USER: RwLock<Option<Uuid>> = RwLock::const_new(None);

/// Cached access token. Read by [`super::http`] on every HTTP request so
/// PostgREST sees `auth.uid()` rather than the anonymous role.
static ACCESS_TOKEN: RwLock<Option<String>> = RwLock::const_new(None);

/// Wire the Supabase client. Called once at app startup with values from
/// `--dart-define` (or equivalent). Safe to call again to switch projects.
pub async fn configure(url: String, anon_key: String) -> anyhow::Result<()> {
    let client = SupabaseClient::new(&url, &anon_key)
        .map_err(|e| anyhow!("Failed to construct Supabase client: {e}"))?;
    *CLIENT.write().await = Some(Arc::new(client));
    *SUPABASE_URL.write().await = Some(url);
    *SUPABASE_ANON_KEY.write().await = Some(anon_key);
    status::emit(SyncStatus::SignedOut);
    Ok(())
}

/// Push the signed-in user's JWT into the Supabase client.
///
/// Dart owns the magic-link flow; on every `onAuthStateChange` event it
/// calls this function. We cache the token locally for direct PostgREST
/// calls and also forward it to the realtime client.
pub async fn set_auth_session(access_token: String, user_id: Uuid) -> anyhow::Result<()> {
    let client = require_client().await?;
    // Best-effort: feed the library so its realtime path picks the JWT
    // up. (HTTP requests bypass the library — see SUPABASE_URL above.)
    if let Err(e) = client.set_auth(&access_token).await {
        tracing::warn!("Failed to set auth on Supabase client: {e}");
    }
    *ACCESS_TOKEN.write().await = Some(access_token);
    *CURRENT_USER.write().await = Some(user_id);
    status::emit(SyncStatus::Idle);
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
        let _ = tokio::time::timeout(FINAL_DRAIN_TIMEOUT, push::drain_now(&db)).await;
        if let Err(e) = push::clear_queue(&db).await {
            tracing::warn!("clear_queue on sign-out: {e:#}");
        }
    }

    // Stop the coordinator before clearing the token so it doesn't make
    // one last unauthenticated request on the way out.
    coordinator::stop().await;
    if let Some(client) = CLIENT.read().await.as_ref() {
        if let Err(e) = client.clear_auth().await {
            tracing::warn!("Failed to clear Supabase auth token: {e}");
        }
    }
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

pub async fn client() -> Option<Arc<SupabaseClient>> {
    CLIENT.read().await.clone()
}

async fn require_client() -> anyhow::Result<Arc<SupabaseClient>> {
    CLIENT
        .read()
        .await
        .clone()
        .ok_or_else(|| anyhow!("Sync is not configured; call configure_sync first"))
}
