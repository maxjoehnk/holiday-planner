use uuid::Uuid;
use super::DB;
use super::events::{self, DataChangeEvent};
use crate::commands::*;
use crate::handlers::*;
use crate::models::*;

#[tracing::instrument]
pub async fn get_trips() -> anyhow::Result<Vec<TripListModel>> {
    let handler = DB.try_get::<TripHandler>().await?;
    handler.get_trips().await
}

#[tracing::instrument]
pub async fn get_upcoming_trips() -> anyhow::Result<Vec<TripListModel>> {
    let handler = DB.try_get::<TripHandler>().await?;
    handler.get_upcoming_trips().await
}

#[tracing::instrument]
pub async fn get_past_trips() -> anyhow::Result<Vec<TripListModel>> {
    let handler = DB.try_get::<TripHandler>().await?;
    handler.get_past_trips().await
}

#[tracing::instrument]
pub async fn get_trip(id: Uuid) -> anyhow::Result<TripOverviewModel> {
    let handler = DB.try_get::<TripHandler>().await?;
    let trip = handler.get_trip_overview(id).await?;

    Ok(trip)
}

#[tracing::instrument]
pub async fn create_trip(command: CreateTrip) -> anyhow::Result<TripOverviewModel> {
    let handler = DB.try_get::<TripHandler>().await?;

    let trip = handler.create_trip(command).await?;
    events::emit(DataChangeEvent::TripsChanged);
    Ok(trip)
}

#[tracing::instrument]
pub async fn update_trip(command: UpdateTrip) -> anyhow::Result<TripOverviewModel> {
    let handler = DB.try_get::<TripHandler>().await?;

    let trip = handler.update_trip(command).await?;
    events::emit(DataChangeEvent::TripChanged { trip_id: trip.id });
    events::emit(DataChangeEvent::TripsChanged);
    Ok(trip)
}

#[tracing::instrument]
pub async fn delete_trip(trip_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<TripHandler>().await?;
    handler.delete_trip(trip_id).await?;
    events::emit(DataChangeEvent::TripsChanged);
    Ok(())
}

#[tracing::instrument]
pub async fn get_trip_packing_list(trip_id: Uuid) -> anyhow::Result<TripPackingListModel> {
    let handler = DB.try_get::<TripPackingListHandler>().await?;
    handler.get_trip_packing_list(trip_id).await
}

#[tracing::instrument]
pub async fn mark_as_packed(trip_id: Uuid, entry_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<TripPackingListHandler>().await?;
    handler.mark_as_packed(trip_id, entry_id).await?;
    events::emit(DataChangeEvent::PackingListChanged { trip_id: Some(trip_id) });
    Ok(())
}

#[tracing::instrument]
pub async fn mark_as_unpacked(trip_id: Uuid, entry_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<TripPackingListHandler>().await?;
    handler.mark_as_unpacked(trip_id, entry_id).await?;
    events::emit(DataChangeEvent::PackingListChanged { trip_id: Some(trip_id) });
    Ok(())
}

#[tracing::instrument]
pub async fn search_locations(query: String) -> anyhow::Result<Vec<LocationEntry>> {
    let handler = DB.try_get::<LocationHandler>().await?;
    handler.search_locations(query).await
}

#[tracing::instrument]
pub async fn add_trip_location(command: AddTripLocation) -> anyhow::Result<()> {
    let handler = DB.try_get::<LocationHandler>().await?;
    let trip_id = command.trip_id;
    handler.add_trip_location(trip_id, command.location).await?;
    events::emit(DataChangeEvent::LocationsChanged { trip_id });
    events::emit(DataChangeEvent::TripChanged { trip_id });
    Ok(())
}

#[tracing::instrument]
pub async fn get_trip_locations(trip_id: Uuid) -> anyhow::Result<Vec<TripLocationListModel>> {
    let handler = DB.try_get::<LocationHandler>().await?;
    handler.get_trip_locations(trip_id).await
}

#[tracing::instrument]
pub async fn search_web_images(command: SearchWebImages) -> anyhow::Result<Vec<WebImage>> {
    let handler = DB.try_get::<TripHandler>().await?;
    handler.search_web_images(command).await
}

#[tracing::instrument]
pub async fn download_web_image(image_url: String) -> anyhow::Result<Vec<u8>> {
    let handler = DB.try_get::<TripHandler>().await?;
    handler.download_web_image(image_url).await
}

#[tracing::instrument]
pub async fn update_coastal_flag(location_id: Uuid, is_coastal: bool) -> anyhow::Result<()> {
    let handler = DB.try_get::<LocationHandler>().await?;
    let trip_id = handler.find_trip_id_for_location(location_id).await.ok().flatten();
    handler.update_coastal_flag(location_id, is_coastal).await?;
    if let Some(trip_id) = trip_id {
        events::emit(DataChangeEvent::LocationsChanged { trip_id });
    }
    Ok(())
}

#[tracing::instrument]
pub async fn get_location_details(location_id: Uuid) -> anyhow::Result<TripLocationListModel> {
    let handler = DB.try_get::<LocationHandler>().await?;
    handler.get_location_details(location_id).await
}

#[tracing::instrument]
pub async fn delete_location(location_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<LocationHandler>().await?;
    let trip_id = handler.find_trip_id_for_location(location_id).await.ok().flatten();
    handler.delete_location(location_id).await?;
    if let Some(trip_id) = trip_id {
        events::emit(DataChangeEvent::LocationsChanged { trip_id });
        events::emit(DataChangeEvent::TripChanged { trip_id });
    }
    Ok(())
}

