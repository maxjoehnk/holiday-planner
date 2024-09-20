use std::ops::Deref;
use crate::database::entities::{location};
use crate::database::entities::location::{Entity as Location};
use sea_orm::{EntityTrait, QueryFilter, ColumnTrait};
use uuid::Uuid;
use crate::database::Database;

pub async fn find_all(db: &Database) -> anyhow::Result<Vec<location::Model>> {
    let locations = Location::find()
        .all(db.deref())
        .await?;

    Ok(locations)
}

pub async fn find_all_by_trip(db: &Database, trip_id: Uuid) -> anyhow::Result<Vec<location::Model>> {
    let locations = Location::find()
        .filter(location::Column::TripId.eq(trip_id))
        .all(db.deref())
        .await?;

    Ok(locations)
}

pub async fn insert(db: &Database, model: location::ActiveModel) -> anyhow::Result<()> {
    Location::insert(model)
        .exec_without_returning(db.deref())
        .await?;
    
    Ok(())
}

pub async fn delete_by_id(db: &Database, id: Uuid) -> anyhow::Result<()> {
    Location::delete_by_id(id)
        .exec(db.deref())
        .await?;

    Ok(())
}
