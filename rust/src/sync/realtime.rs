//! Supabase Realtime client.
//!
//! `supabase-lib-rs`'s realtime module doesn't forward the user's JWT in
//! the Phoenix `phx_join` payload, so RLS-protected channels deliver
//! zero events. We bypass it with a focused implementation on
//! `tokio-tungstenite`: connect to the realtime WebSocket, join one
//! channel per synced table with `access_token` in the join payload,
//! parse incoming `postgres_changes` events, and route them through
//! [`apply::apply_remote_row`].
//!
//! Events that arrive between subscription and the coordinator's
//! [`RealtimeWorker::go_live`] call are buffered so the initial pull
//! can complete without losing concurrent updates.

use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;

use anyhow::{anyhow, Context};
use futures_util::{SinkExt, StreamExt};
use serde_json::{json, Value};
use tokio::sync::{watch, Mutex};
use tokio::task::JoinHandle;
use tokio_tungstenite::connect_async;
use tokio_tungstenite::tungstenite::Message;

use crate::database::Database;
use crate::sync::pull::SYNCED_TABLES;
use crate::sync::{apply, session};

const HEARTBEAT: Duration = Duration::from_secs(25);
const BACKOFF_INITIAL: Duration = Duration::from_secs(2);
const BACKOFF_MAX: Duration = Duration::from_secs(60);

pub struct RealtimeWorker {
    db: Database,
    /// Some while in the initial-pull window; None once we go live and
    /// the receive loop applies events inline.
    buffer: Arc<Mutex<Option<Vec<BufferedEvent>>>>,
    task: Option<JoinHandle<()>>,
    shutdown_tx: Option<watch::Sender<bool>>,
}

struct BufferedEvent {
    table: String,
    row: Value,
}

impl RealtimeWorker {
    pub fn new(db: Database) -> Self {
        Self {
            db,
            buffer: Arc::new(Mutex::new(Some(Vec::new()))),
            task: None,
            shutdown_tx: None,
        }
    }

    /// Start the WS worker. Returns once the worker task is spawned —
    /// the actual connect happens in the background. Reconnection is
    /// handled internally with exponential backoff.
    pub async fn subscribe(&mut self) -> anyhow::Result<()> {
        let url = build_ws_url().await?;
        let (sd_tx, sd_rx) = watch::channel(false);
        self.shutdown_tx = Some(sd_tx);

        let buffer = self.buffer.clone();
        let db = self.db.clone();

        let handle = tokio::spawn(run_worker(url, buffer, db, sd_rx));
        self.task = Some(handle);
        Ok(())
    }

    /// Drain buffered events and switch the receive loop into
    /// pass-through mode. LWW inside `apply` handles dedup vs the just-
    /// completed pull.
    pub async fn go_live(&self) -> anyhow::Result<()> {
        let drained = {
            let mut guard = self.buffer.lock().await;
            guard.take().unwrap_or_default()
        };
        if drained.is_empty() {
            return Ok(());
        }
        tracing::debug!("realtime: draining {} buffered event(s)", drained.len());
        for ev in drained {
            if let Err(e) = apply::apply_remote_row(&self.db, &ev.table, ev.row).await {
                tracing::warn!("apply buffered {}: {e:#}", ev.table);
            }
        }
        Ok(())
    }

    /// Signal the worker to shut down and wait briefly for it to wind up.
    pub async fn unsubscribe_all(&mut self) {
        if let Some(tx) = self.shutdown_tx.take() {
            let _ = tx.send(true);
        }
        if let Some(handle) = self.task.take() {
            let _ = tokio::time::timeout(Duration::from_secs(2), handle).await;
        }
    }
}

async fn build_ws_url() -> anyhow::Result<String> {
    let url = session::supabase_url()
        .await
        .ok_or_else(|| anyhow!("Supabase URL not configured"))?;
    let key = session::anon_key()
        .await
        .ok_or_else(|| anyhow!("Supabase anon key not configured"))?;
    let host = url
        .trim_start_matches("https://")
        .trim_start_matches("http://")
        .trim_end_matches('/');
    Ok(format!(
        "wss://{host}/realtime/v1/websocket?apikey={key}&vsn=2.0.0"
    ))
}

async fn run_worker(
    url: String,
    buffer: Arc<Mutex<Option<Vec<BufferedEvent>>>>,
    db: Database,
    mut shutdown_rx: watch::Receiver<bool>,
) {
    let mut backoff = BACKOFF_INITIAL;
    loop {
        if *shutdown_rx.borrow() {
            return;
        }
        match run_session(&url, &buffer, &db, &mut shutdown_rx).await {
            Ok(()) => return,
            Err(e) => {
                tracing::warn!("realtime session: {e:#}");
            }
        }
        tokio::select! {
            biased;
            _ = shutdown_rx.changed() => {
                if *shutdown_rx.borrow() { return; }
            }
            _ = tokio::time::sleep(backoff) => {}
        }
        backoff = (backoff * 2).min(BACKOFF_MAX);
    }
}

async fn run_session(
    url: &str,
    buffer: &Arc<Mutex<Option<Vec<BufferedEvent>>>>,
    db: &Database,
    shutdown_rx: &mut watch::Receiver<bool>,
) -> anyhow::Result<()> {
    let (ws, _) = connect_async(url).await.context("realtime ws connect")?;
    let (mut sink, mut stream) = ws.split();

    let access_token = session::access_token()
        .await
        .ok_or_else(|| anyhow!("realtime: not signed in"))?;

    // One topic per synced table. The join payload's `postgres_changes`
    // config tells the server what to forward, and `access_token`
    // is what makes RLS-protected rows visible.
    let mut next_ref: u64 = 1;
    let mut join_refs: HashMap<u64, String> = HashMap::new();
    for table in SYNCED_TABLES {
        let join_ref = next_ref;
        next_ref += 1;
        let req_ref = next_ref;
        next_ref += 1;
        let topic = format!("realtime:public:{table}");
        let payload = json!({
            "config": {
                "postgres_changes": [
                    {"event": "*", "schema": "public", "table": table}
                ],
                "broadcast": {"ack": false, "self": false},
                "presence": {"key": ""}
            },
            "access_token": access_token,
        });
        let msg = json!([
            join_ref.to_string(),
            req_ref.to_string(),
            topic,
            "phx_join",
            payload
        ]);
        sink.send(Message::Text(msg.to_string()))
            .await
            .context("send phx_join")?;
        join_refs.insert(join_ref, topic);
    }

    let mut heartbeat = tokio::time::interval(HEARTBEAT);
    heartbeat.tick().await; // skip the immediate first tick

    loop {
        tokio::select! {
            biased;
            _ = shutdown_rx.changed() => {
                if *shutdown_rx.borrow() {
                    let _ = sink.send(Message::Close(None)).await;
                    return Ok(());
                }
            }
            _ = heartbeat.tick() => {
                let r = next_ref;
                next_ref += 1;
                let msg = json!([Value::Null, r.to_string(), "phoenix", "heartbeat", {}]);
                sink.send(Message::Text(msg.to_string()))
                    .await
                    .context("heartbeat send")?;
            }
            incoming = stream.next() => {
                let msg = match incoming {
                    Some(Ok(m)) => m,
                    Some(Err(e)) => return Err(anyhow!("ws stream: {e}")),
                    None => return Err(anyhow!("ws closed")),
                };
                match msg {
                    Message::Text(text) => {
                        if let Err(e) = handle_text(&text, buffer, db).await {
                            tracing::warn!("realtime message: {e:#}");
                        }
                    }
                    Message::Ping(p) => {
                        let _ = sink.send(Message::Pong(p)).await;
                    }
                    Message::Close(_) => return Err(anyhow!("ws close frame")),
                    _ => {}
                }
            }
        }
    }
}

/// Decode one Phoenix v2 frame and route postgres_changes payloads.
/// Frame format: `[join_ref, ref, topic, event, payload]`.
async fn handle_text(
    text: &str,
    buffer: &Arc<Mutex<Option<Vec<BufferedEvent>>>>,
    db: &Database,
) -> anyhow::Result<()> {
    let arr: Value = serde_json::from_str(text)?;
    let Some(arr) = arr.as_array() else { return Ok(()) };
    if arr.len() < 5 {
        return Ok(());
    }
    let event = arr[3].as_str().unwrap_or_default();
    if event != "postgres_changes" {
        // phx_reply (join ack), system, broadcast etc. — nothing to do.
        return Ok(());
    }
    let payload = &arr[4];
    let data = payload.get("data").cloned().unwrap_or(Value::Null);

    let table = data
        .get("table")
        .and_then(|v| v.as_str())
        .unwrap_or_default()
        .to_string();
    if table.is_empty() {
        return Ok(());
    }

    // INSERT/UPDATE carry the row in `record`; DELETE carries the
    // pre-image in `old_record`. Either way we want a row to apply.
    let change_type = data.get("type").and_then(|v| v.as_str()).unwrap_or_default();
    let row = match change_type {
        "DELETE" => data.get("old_record").cloned(),
        _ => data.get("record").cloned(),
    };
    let Some(mut row) = row else { return Ok(()) };

    // Postgres realtime DELETE events don't carry `deleted_at`, but
    // `apply` expects soft-delete semantics. Synthesize one so the
    // apply path's delete branch fires.
    if change_type == "DELETE" {
        if let Some(obj) = row.as_object_mut() {
            if !obj.contains_key("deleted_at") {
                obj.insert("deleted_at".into(), json!(chrono::Utc::now()));
            }
            if !obj.contains_key("updated_at") {
                obj.insert("updated_at".into(), json!(chrono::Utc::now()));
            }
        }
    }

    let mut guard = buffer.lock().await;
    match guard.as_mut() {
        Some(buf) => buf.push(BufferedEvent { table, row }),
        None => {
            drop(guard);
            if let Err(e) = apply::apply_remote_row(db, &table, row).await {
                tracing::warn!("realtime apply {table}: {e:#}");
            }
        }
    }
    Ok(())
}
