use sled::Db;
use typed_sled::Tree;
use uuid::Uuid;

use crate::models::{Attachment, PackingListEntry, Trip, TripPackingListEntry};

#[cfg(target_os = "android")]
mod storage {
    use std::path::Path;

    pub fn get_path() -> &'static Path {
        Path::new("/data/data/me.maxjoehnk.holiday_planner/files/database")
    }
}

#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
mod storage {
    use std::path::Path;

    pub fn get_path() -> &'static Path {
        Path::new(".database")
    }
}

#[derive(Clone)]
pub struct Database {
    db: Db,
}

impl Database {
    #[tracing::instrument]
    pub fn new() -> Self {
        let path = storage::get_path();
        tracing::info!("Opening database at {path:?}");
        let db = sled::Config::new()
            .path(path)
            .mode(sled::Mode::LowSpace)
            .open()
            .unwrap();

        Self { db }
    }

    pub fn trip_tree(&self) -> Tree<Uuid, Trip> {
        Tree::open(&self.db, "trips")
    }

    pub fn packing_list_tree(&self) -> Tree<Uuid, PackingListEntry> {
        Tree::open(&self.db, "packing_list")
    }

    pub fn attachments_tree(&self) -> Tree<Uuid, Attachment> {
        Tree::open(&self.db, "attachments")
    }

    pub fn trip_packing_list_tree(&self) -> Tree<Uuid, Vec<TripPackingListEntry>> {
        Tree::open(&self.db, "trip_packing_list")
    }
}
