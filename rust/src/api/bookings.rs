use uuid::Uuid;
use crate::api::DB;
use crate::api::events::{self, DataChangeEvent};
use crate::commands::{AddReservation, AddCarRental, UpdateReservation, UpdateCarRental};
use crate::handlers::{BookingHandler, HandlerCreator};
use crate::models::bookings::Booking;

#[tracing::instrument]
pub async fn add_reservation(command: AddReservation) -> anyhow::Result<()> {
    let handler = DB.try_get::<BookingHandler>().await?;
    let trip_id = command.trip_id;
    handler.add_reservation(command).await?;
    events::emit(DataChangeEvent::BookingsChanged { trip_id: Some(trip_id) });
    Ok(())
}

#[tracing::instrument]
pub async fn update_reservation(command: UpdateReservation) -> anyhow::Result<()> {
    let handler = DB.try_get::<BookingHandler>().await?;
    handler.update_reservation(command).await?;
    events::emit(DataChangeEvent::BookingsChanged { trip_id: None });
    Ok(())
}

#[tracing::instrument]
pub async fn delete_reservation(reservation_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<BookingHandler>().await?;
    handler.delete_reservation(reservation_id).await?;
    events::emit(DataChangeEvent::BookingsChanged { trip_id: None });
    Ok(())
}

#[tracing::instrument]
pub async fn add_car_rental(command: AddCarRental) -> anyhow::Result<()> {
    let handler = DB.try_get::<BookingHandler>().await?;
    let trip_id = command.trip_id;
    handler.add_car_rental(command).await?;
    events::emit(DataChangeEvent::BookingsChanged { trip_id: Some(trip_id) });
    Ok(())
}

#[tracing::instrument]
pub async fn update_car_rental(command: UpdateCarRental) -> anyhow::Result<()> {
    let handler = DB.try_get::<BookingHandler>().await?;
    handler.update_car_rental(command).await?;
    events::emit(DataChangeEvent::BookingsChanged { trip_id: None });
    Ok(())
}

#[tracing::instrument]
pub async fn delete_car_rental(car_rental_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<BookingHandler>().await?;
    handler.delete_car_rental(car_rental_id).await?;
    events::emit(DataChangeEvent::BookingsChanged { trip_id: None });
    Ok(())
}

#[tracing::instrument]
pub async fn get_trip_bookings(trip_id: Uuid) -> anyhow::Result<Vec<Booking>> {
    let handler = DB.try_get::<BookingHandler>().await?;
    handler.get_trip_bookings(trip_id).await
}
