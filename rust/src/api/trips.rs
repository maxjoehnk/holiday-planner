use uuid::Uuid;
use super::DB;
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

    handler.create_trip(command).await
}

#[tracing::instrument]
pub async fn update_trip(command: UpdateTrip) -> anyhow::Result<TripOverviewModel> {
    let handler = DB.try_get::<TripHandler>().await?;

    handler.update_trip(command).await
}

#[tracing::instrument]
pub async fn get_trip_packing_list(trip_id: Uuid) -> anyhow::Result<TripPackingListModel> {
    let handler = DB.try_get::<TripPackingListHandler>().await?;
    handler.get_trip_packing_list(trip_id).await
}

#[tracing::instrument]
pub async fn mark_as_packed(trip_id: Uuid, entry_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<TripPackingListHandler>().await?;
    handler.mark_as_packed(trip_id, entry_id).await
}

#[tracing::instrument]
pub async fn mark_as_unpacked(trip_id: Uuid, entry_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<TripPackingListHandler>().await?;
    handler.mark_as_unpacked(trip_id, entry_id).await
}

#[tracing::instrument]
pub async fn search_locations(query: String) -> anyhow::Result<Vec<LocationEntry>> {
    let handler = DB.try_get::<LocationHandler>().await?;
    handler.search_locations(query).await
}

#[tracing::instrument]
pub async fn add_trip_location(command: AddTripLocation) -> anyhow::Result<()> {
    let handler = DB.try_get::<LocationHandler>().await?;
    handler.add_trip_location(command.trip_id, command.location).await
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
