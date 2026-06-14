//! Sync lifecycle: spawn the realtime worker once a user is signed in,
//! pull initial deltas, drain the buffer, then stay alive until the
//! session is cleared.
//!
//! Reconnection on transient WS drops is best-effort: an error during
//! subscribe or pull causes an exponential backoff and a fresh attempt.

use std::sync::OnceLock;
use std::time::Duration;

use tokio::sync::{Notify, RwLock};
use tokio::task::JoinHandle;

use crate::api::sync::SyncStatus;
use crate::database::Database;
use crate::sync::{pull, realtime::RealtimeWorker, session, status};

const INITIAL_BACKOFF: Duration = Duration::from_secs(5);
const MAX_BACKOFF: Duration = Duration::from_secs(60);
/// How often the alive loop ticks — also the cadence at which we
/// re-pull deltas as a backstop while realtime is broken in the SDK.
const ALIVE_POLL: Duration = Duration::from_secs(30);

static HANDLE: RwLock<Option<JoinHandle<()>>> = RwLock::const_new(None);
static STOP_NOTIFY: OnceLock<Notify> = OnceLock::new();
static WAKE_NOTIFY: OnceLock<Notify> = OnceLock::new();

fn stop_signal() -> &'static Notify {
    STOP_NOTIFY.get_or_init(Notify::new)
}

fn wake_signal() -> &'static Notify {
    WAKE_NOTIFY.get_or_init(Notify::new)
}

/// Ask the coordinator to run a pull immediately rather than waiting for
/// the next periodic tick. Used when a realtime event hints at data we
/// don't have yet — e.g. we just got added as a member of a trip whose
/// rows haven't been pulled.
pub fn request_pull() {
    wake_signal().notify_one();
}

/// Spawn the coordinator if it isn't already running. Idempotent.
pub async fn start(db: Database) {
    let mut guard = HANDLE.write().await;
    if guard.as_ref().is_some_and(|h| !h.is_finished()) {
        return;
    }
    let handle = tokio::spawn(run(db));
    *guard = Some(handle);
}

/// Tell the coordinator to wind down. Called on sign-out.
pub async fn stop() {
    stop_signal().notify_waiters();
    let mut guard = HANDLE.write().await;
    if let Some(handle) = guard.take() {
        // Give the task a chance to clean up via the stop signal; abort as a fallback.
        let _ = tokio::time::timeout(Duration::from_secs(2), handle).await;
    }
}

async fn run(db: Database) {
    let mut backoff = INITIAL_BACKOFF;
    loop {
        if session::current_user().await.is_none() {
            status::emit(SyncStatus::SignedOut);
            return;
        }

        status::emit(SyncStatus::Connecting);

        let mut worker = RealtimeWorker::new(db.clone());

        // 1. Subscribe — opens the WS and starts buffering events.
        if let Err(e) = worker.subscribe().await {
            tracing::warn!("realtime subscribe failed: {e:#}");
            status::emit(SyncStatus::Error { message: e.to_string() });
            if !wait_or_stop(backoff).await {
                return;
            }
            backoff = next_backoff(backoff);
            continue;
        }

        // 2. Pull deltas
        status::emit(SyncStatus::Syncing);
        if let Err(e) = pull::pull_all(&db).await {
            tracing::warn!("pull failed: {e:#}");
            status::emit(SyncStatus::Error { message: e.to_string() });
            worker.unsubscribe_all().await;
            if !wait_or_stop(backoff).await {
                return;
            }
            backoff = next_backoff(backoff);
            continue;
        }

        // 3. Drain buffer and go live (LWW protects against dupes)
        if let Err(e) = worker.go_live().await {
            tracing::warn!("go_live: {e:#}");
        }

        status::emit(SyncStatus::Live);
        backoff = INITIAL_BACKOFF;

        // 4. Stay alive. The realtime worker reconnects internally on
        //    WS drops; we still tick a periodic pull as a backstop for
        //    cases the realtime channel doesn't surface (eg. trips
        //    shared via a `trip_members` row inserted while offline).
        loop {
            tokio::select! {
                _ = stop_signal().notified() => {
                    worker.unsubscribe_all().await;
                    status::emit(SyncStatus::SignedOut);
                    return;
                }
                _ = wake_signal().notified() => {
                    if session::current_user().await.is_none() {
                        continue;
                    }
                    if let Err(e) = pull::pull_all(&db).await {
                        tracing::warn!("on-demand pull: {e:#}");
                    }
                }
                _ = tokio::time::sleep(ALIVE_POLL) => {
                    if session::current_user().await.is_none() {
                        worker.unsubscribe_all().await;
                        status::emit(SyncStatus::SignedOut);
                        return;
                    }
                    if let Err(e) = pull::pull_all(&db).await {
                        tracing::warn!("periodic pull: {e:#}");
                    }
                }
            }
        }
    }
}

async fn wait_or_stop(d: Duration) -> bool {
    tokio::select! {
        _ = stop_signal().notified() => false,
        _ = tokio::time::sleep(d) => true,
    }
}

fn next_backoff(current: Duration) -> Duration {
    (current * 2).min(MAX_BACKOFF)
}
