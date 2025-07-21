use uuid::Uuid;
use crate::api::DB;
use crate::commands::{AddReservation, AddCarRental, UpdateReservation, UpdateCarRental};
use crate::handlers::{BookingHandler, HandlerCreator};
use crate::models::bookings::Booking;

#[tracing::instrument]
pub async fn add_reservation(command: AddReservation) -> anyhow::Result<()> {
    let handler = DB.try_get::<BookingHandler>().await?;
    handler.add_reservation(command).await
}

#[tracing::instrument]
pub async fn update_reservation(command: UpdateReservation) -> anyhow::Result<()> {
    let handler = DB.try_get::<BookingHandler>().await?;
    handler.update_reservation(command).await
}

#[tracing::instrument]
pub async fn delete_reservation(reservation_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<BookingHandler>().await?;
    handler.delete_reservation(reservation_id).await
}

#[tracing::instrument]
pub async fn add_car_rental(command: AddCarRental) -> anyhow::Result<()> {
    let handler = DB.try_get::<BookingHandler>().await?;
    handler.add_car_rental(command).await
}

#[tracing::instrument]
pub async fn update_car_rental(command: UpdateCarRental) -> anyhow::Result<()> {
    let handler = DB.try_get::<BookingHandler>().await?;
    handler.update_car_rental(command).await
}

#[tracing::instrument]
pub async fn delete_car_rental(car_rental_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<BookingHandler>().await?;
    handler.delete_car_rental(car_rental_id).await
}

#[tracing::instrument]
pub async fn get_trip_bookings(trip_id: Uuid) -> anyhow::Result<Vec<Booking>> {
    let handler = DB.try_get::<BookingHandler>().await?;
    handler.get_trip_bookings(trip_id).await
}
