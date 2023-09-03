use std::ops::Deref;
use parking_lot::{RwLock, RwLockReadGuard};
use uuid::Uuid;

pub use crate::commands::*;
use crate::database::Database;
use crate::handlers::*;
use crate::jobs::BackgroundJobHandler;
pub use crate::models::*;

static DB: RwLock<Option<Database>> = RwLock::new(None);

pub struct HandlerGuard<'a, T> {
    db_guard: RwLockReadGuard<'a, Option<Database>>,
    handler: T,
}

impl<'a, T> Deref for HandlerGuard<'a, T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.handler
    }
}

impl HandlerCreator for RwLock<Option<Database>> {
    type Guard<'a, T: Handler> = HandlerGuard<'a, T>;

    fn try_get<'a, T: Handler>(&'a self) -> anyhow::Result<Self::Guard<'a, T>> {
        let db_guard = self.read();
        let db = db_guard.as_ref().unwrap();
        let handler = T::create(db.clone());

        Ok(HandlerGuard {
            db_guard,
            handler,
        })
    }
}

#[tracing::instrument]
pub fn init() {
    crate::logger::init();
    let mut db = DB.write();
    *db = Some(Database::new());
}

#[tracing::instrument]
pub fn get_trips() -> Vec<Trip> {
    let handler = DB.try_get::<TripHandler>().unwrap();
    handler.get_trips().unwrap()
}

#[tracing::instrument]
pub fn create_trip(command: CreateTrip) -> Trip {
    let handler = DB.try_get::<TripHandler>().unwrap();
    handler.create_trip(command).unwrap()
}

#[tracing::instrument]
pub fn get_packing_list() -> Vec<PackingListEntry> {
    let handler = DB.try_get::<PackingListHandler>().unwrap();
    handler.get_packing_list().unwrap()
}

#[tracing::instrument]
pub fn add_packing_list_entry(command: AddPackingListEntry) -> PackingListEntry {
    let handler = DB.try_get::<PackingListHandler>().unwrap();
    handler.add_packing_list_entry(command).unwrap()
}

#[tracing::instrument]
pub fn delete_packing_list_entry(command: DeletePackingListEntry) {
    let handler = DB.try_get::<PackingListHandler>().unwrap();
    handler.delete_packing_list_entry(command).unwrap();
}

#[tracing::instrument]
pub fn get_trip_packing_list(trip_id: Uuid) -> TripPackingListModel {
    let handler = DB.try_get::<TripPackingListHandler>().unwrap();
    handler.get_trip_packing_list(trip_id).unwrap()
}

#[tracing::instrument]
pub fn mark_as_packed(trip_id: Uuid, entry_id: Uuid) {
    let handler = DB.try_get::<TripPackingListHandler>().unwrap();
    handler.mark_as_packed(trip_id, entry_id).unwrap();
}

#[tracing::instrument]
pub fn mark_as_unpacked(trip_id: Uuid, entry_id: Uuid) {
    let handler = DB.try_get::<TripPackingListHandler>().unwrap();
    handler.mark_as_unpacked(trip_id, entry_id).unwrap();
}

#[tracing::instrument]
pub fn search_locations(query: String) -> Vec<LocationEntry> {
    let handler = DB.try_get::<LocationHandler>().unwrap();
    handler.search_locations(query).unwrap()
}

#[tracing::instrument]
pub fn add_trip_location(command: AddTripLocation) {
    let handler = DB.try_get::<TripHandler>().unwrap();
    handler.add_trip_location(command.trip_id, command.location).unwrap();
}

#[tracing::instrument]
pub fn run_background_jobs() {
    let handler = DB.try_get::<BackgroundJobHandler>().unwrap();
    handler.run().unwrap();
}
