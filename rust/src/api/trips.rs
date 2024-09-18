use uuid::Uuid;
use super::DB;
use crate::commands::*;
use crate::handlers::*;
use crate::models::*;

#[tracing::instrument]
pub fn get_trips() -> anyhow::Result<Vec<Trip>> {
    let handler = DB.try_get::<TripHandler>()?;
    handler.get_trips()
}

#[tracing::instrument]
pub fn get_trip(id: Uuid) -> anyhow::Result<Option<Trip>> {
    let handler = DB.try_get::<TripHandler>()?;
    handler.get_trip(id)
}

#[tracing::instrument]
pub fn create_trip(command: CreateTrip) -> anyhow::Result<Trip> {
    let handler = DB.try_get::<TripHandler>()?;
    handler.create_trip(command)
}

#[tracing::instrument]
pub fn get_trip_packing_list(trip_id: Uuid) -> anyhow::Result<TripPackingListModel> {
    let handler = DB.try_get::<TripPackingListHandler>()?;
    handler.get_trip_packing_list(trip_id)
}

#[tracing::instrument]
pub fn mark_as_packed(trip_id: Uuid, entry_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<TripPackingListHandler>()?;
    handler.mark_as_packed(trip_id, entry_id)
}

#[tracing::instrument]
pub fn mark_as_unpacked(trip_id: Uuid, entry_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<TripPackingListHandler>()?;
    handler.mark_as_unpacked(trip_id, entry_id)
}

#[tracing::instrument]
pub async fn search_locations(query: String) -> anyhow::Result<Vec<LocationEntry>> {
    let handler = DB.try_get::<LocationHandler>()?;
    handler.search_locations(query).await
}

#[tracing::instrument]
pub fn add_trip_location(command: AddTripLocation) -> anyhow::Result<()> {
    let handler = DB.try_get::<TripHandler>()?;
    handler.add_trip_location(command.trip_id, command.location)
}
