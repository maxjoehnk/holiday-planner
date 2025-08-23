use std::ops::Deref;
use chrono::Utc;
use crate::database::entities::train;
use crate::database::entities::train::Entity as Train;
use sea_orm::{EntityTrait, QueryFilter, QueryOrder, ColumnTrait};
use uuid::Uuid;
use crate::database::Database;

pub async fn find_upcoming_trains(db: &Database, trip_id: Uuid) -> anyhow::Result<Vec<train::Model>> {
    let now = Utc::now();
    let train = Train::find()
        .filter(train::Column::TripId.eq(trip_id))
        .filter(train::Column::ScheduledDepartureTime.gt(now).or(train::Column::ScheduledArrivalTime.gt(now)))
        .order_by_asc(train::Column::ScheduledDepartureTime)
        .all(db.deref())
        .await?;

    Ok(train)
}

pub async fn find_all_trains_by_trip(db: &Database, trip_id: Uuid) -> anyhow::Result<Vec<train::Model>> {
    let trains = Train::find()
        .filter(train::Column::TripId.eq(trip_id))
        .order_by_asc(train::Column::ScheduledDepartureTime)
        .all(db.deref())
        .await?;

    Ok(trains)
}

pub async fn find_train_by_id(db: &Database, id: Uuid) -> anyhow::Result<Option<train::Model>> {
    let train = Train::find_by_id(id)
        .one(db.deref())
        .await?;

    Ok(train)
}

pub async fn insert_train(db: &Database, model: train::ActiveModel) -> anyhow::Result<()> {
    Train::insert(model)
        .exec_without_returning(db.deref())
        .await?;
    
    Ok(())
}

pub async fn update_train(db: &Database, model: train::ActiveModel) -> anyhow::Result<()> {
    Train::update(model)
        .exec(db.deref())
        .await?;
    
    Ok(())
}

pub async fn delete_train_by_id(db: &Database, id: Uuid) -> anyhow::Result<()> {
    Train::delete_by_id(id)
        .exec(db.deref())
        .await?;

    Ok(())
}
