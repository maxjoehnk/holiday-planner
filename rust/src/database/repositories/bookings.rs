use std::ops::Deref;
use crate::database::entities::{reservation, car_rental};
use crate::database::entities::reservation::Entity as Reservation;
use crate::database::entities::car_rental::Entity as CarRental;
use sea_orm::{EntityTrait, QueryFilter, QueryOrder, ColumnTrait};
use uuid::Uuid;
use crate::database::Database;

pub async fn find_all_reservations_by_trip(db: &Database, trip_id: Uuid) -> anyhow::Result<Vec<reservation::Model>> {
    let reservations = Reservation::find()
        .filter(reservation::Column::TripId.eq(trip_id))
        .order_by_asc(reservation::Column::StartDate)
        .all(db.deref())
        .await?;

    Ok(reservations)
}

pub async fn find_reservation_by_id(db: &Database, id: Uuid) -> anyhow::Result<Option<reservation::Model>> {
    let reservation = Reservation::find_by_id(id)
        .one(db.deref())
        .await?;

    Ok(reservation)
}

pub async fn insert_reservation(db: &Database, model: reservation::ActiveModel) -> anyhow::Result<()> {
    Reservation::insert(model)
        .exec_without_returning(db.deref())
        .await?;
    
    Ok(())
}

pub async fn update_reservation(db: &Database, model: reservation::ActiveModel) -> anyhow::Result<()> {
    Reservation::update(model)
        .exec(db.deref())
        .await?;
    
    Ok(())
}

pub async fn delete_reservation_by_id(db: &Database, id: Uuid) -> anyhow::Result<()> {
    Reservation::delete_by_id(id)
        .exec(db.deref())
        .await?;

    Ok(())
}

pub async fn find_all_car_rentals_by_trip(db: &Database, trip_id: Uuid) -> anyhow::Result<Vec<car_rental::Model>> {
    let car_rentals = CarRental::find()
        .filter(car_rental::Column::TripId.eq(trip_id))
        .order_by_asc(car_rental::Column::PickUpDate)
        .all(db.deref())
        .await?;

    Ok(car_rentals)
}

pub async fn find_car_rental_by_id(db: &Database, id: Uuid) -> anyhow::Result<Option<car_rental::Model>> {
    let car_rental = CarRental::find_by_id(id)
        .one(db.deref())
        .await?;

    Ok(car_rental)
}

pub async fn insert_car_rental(db: &Database, model: car_rental::ActiveModel) -> anyhow::Result<()> {
    CarRental::insert(model)
        .exec_without_returning(db.deref())
        .await?;
    
    Ok(())
}

pub async fn update_car_rental(db: &Database, model: car_rental::ActiveModel) -> anyhow::Result<()> {
    CarRental::update(model)
        .exec(db.deref())
        .await?;
    
    Ok(())
}

pub async fn delete_car_rental_by_id(db: &Database, id: Uuid) -> anyhow::Result<()> {
    CarRental::delete_by_id(id)
        .exec(db.deref())
        .await?;

    Ok(())
}
