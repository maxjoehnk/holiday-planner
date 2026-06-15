use uuid::Uuid;

use crate::api::DB;
use crate::commands::{
    AddTripDayLocation, AssignItemToDay, RemoveTripDayLocation, ReorderDay,
    SetPrimaryTripDayLocation, SetTripDayTitle, UnassignItem,
};
use crate::handlers::{HandlerCreator, TripDayHandler};
use crate::models::{TripDayView, UnassignedItems};

#[tracing::instrument]
pub async fn get_trip_days(trip_id: Uuid) -> anyhow::Result<Vec<TripDayView>> {
    let handler = DB.try_get::<TripDayHandler>().await?;
    handler.get_trip_days(trip_id).await
}

#[tracing::instrument]
pub async fn get_unassigned_day_items(trip_id: Uuid) -> anyhow::Result<UnassignedItems> {
    let handler = DB.try_get::<TripDayHandler>().await?;
    handler.get_unassigned_items(trip_id).await
}

#[tracing::instrument]
pub async fn assign_item_to_day(command: AssignItemToDay) -> anyhow::Result<()> {
    let handler = DB.try_get::<TripDayHandler>().await?;
    handler.assign_item_to_day(command).await
}

#[tracing::instrument]
pub async fn unassign_day_item(trip_id: Uuid, command: UnassignItem) -> anyhow::Result<()> {
    let handler = DB.try_get::<TripDayHandler>().await?;
    handler.unassign_item(trip_id, command).await
}

#[tracing::instrument]
pub async fn reorder_trip_day(trip_id: Uuid, command: ReorderDay) -> anyhow::Result<()> {
    let handler = DB.try_get::<TripDayHandler>().await?;
    handler.reorder_day(trip_id, command).await
}

#[tracing::instrument]
pub async fn set_trip_day_title(command: SetTripDayTitle) -> anyhow::Result<()> {
    let handler = DB.try_get::<TripDayHandler>().await?;
    handler.set_title(command).await
}

#[tracing::instrument]
pub async fn add_trip_day_location(command: AddTripDayLocation) -> anyhow::Result<()> {
    let handler = DB.try_get::<TripDayHandler>().await?;
    handler.add_location(command).await
}

#[tracing::instrument]
pub async fn remove_trip_day_location(
    trip_id: Uuid,
    command: RemoveTripDayLocation,
) -> anyhow::Result<()> {
    let handler = DB.try_get::<TripDayHandler>().await?;
    handler.remove_location(trip_id, command).await
}

#[tracing::instrument]
pub async fn set_primary_trip_day_location(
    trip_id: Uuid,
    command: SetPrimaryTripDayLocation,
) -> anyhow::Result<()> {
    let handler = DB.try_get::<TripDayHandler>().await?;
    handler.set_primary_location(trip_id, command).await
}
