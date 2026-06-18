use std::sync::OnceLock;
use tokio::sync::broadcast;

use crate::api::sync::SyncStatus;

const CHANNEL_CAPACITY: usize = 16;

static STATUS_BUS: OnceLock<broadcast::Sender<SyncStatus>> = OnceLock::new();

fn bus() -> &'static broadcast::Sender<SyncStatus> {
    STATUS_BUS.get_or_init(|| broadcast::channel(CHANNEL_CAPACITY).0)
}

pub fn emit(status: SyncStatus) {
    let _ = bus().send(status);
}

pub fn subscribe() -> broadcast::Receiver<SyncStatus> {
    bus().subscribe()
}
