use uuid::Uuid;
use crate::api::DB;
use crate::commands::{AddTripAccommodation, UpdateTripAccommodation};
use crate::handlers::{AccommodationHandler, HandlerCreator};
use crate::models::{AccommodationModel};

#[tracing::instrument]
pub async fn get_trip_accommodations(trip_id: Uuid) -> anyhow::Result<Vec<AccommodationModel>> {
    let handler = DB.try_get::<AccommodationHandler>().await?;
    handler.get_trip_accommodations(trip_id).await
}

#[tracing::instrument]
pub async fn add_trip_accommodation(command: AddTripAccommodation) -> anyhow::Result<()> {
    let handler = DB.try_get::<AccommodationHandler>().await?;
    handler.add_accommodation(command).await
}

#[tracing::instrument]
pub async fn update_trip_accommodation(command: UpdateTripAccommodation) -> anyhow::Result<()> {
    let handler = DB.try_get::<AccommodationHandler>().await?;
    handler.update_accommodation(command).await
}

#[tracing::instrument]
pub async fn delete_accommodation(accommodation_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<AccommodationHandler>().await?;
    handler.delete_accommodation(accommodation_id).await
}
