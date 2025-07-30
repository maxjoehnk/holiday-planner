use std::ops::Deref;
use crate::database::entities::{location, trip};
use crate::database::entities::location::{Entity as Location};
use sea_orm::{EntityTrait, QueryFilter, ColumnTrait, ActiveModelTrait, Set, ConnectionTrait, QuerySelect, JoinType, RelationTrait};
use uuid::Uuid;
use crate::database::{Database, DbResult};
use chrono::Utc;

pub async fn find_all_by_trip(db: &Database, trip_id: Uuid) -> anyhow::Result<Vec<location::Model>> {
    let locations = Location::find()
        .filter(location::Column::TripId.eq(trip_id))
        .all(db.deref())
        .await?;

    Ok(locations)
}

pub async fn insert(db: &Database, model: location::ActiveModel) -> DbResult<()> {
    Location::insert(model)
        .exec_without_returning(db.deref())
        .await?;
    
    Ok(())
}

pub async fn find_by_id(db: &Database, id: Uuid) -> anyhow::Result<Option<location::Model>> {
    let location = Location::find_by_id(id)
        .one(db.deref())
        .await?;

    Ok(location)
}

pub async fn update_coastal_flag(db: &Database, id: Uuid, is_coastal: bool) -> DbResult<()> {
    let location = Location::find_by_id(id)
        .one(db.deref())
        .await?;

    if let Some(location) = location {
        let mut active_model: location::ActiveModel = location.into();
        active_model.is_coastal = Set(is_coastal);
        active_model.update(db.deref()).await?;
    }

    Ok(())
}

pub async fn update_tidal_information_timestamp(db: &impl ConnectionTrait, id: Uuid) -> DbResult<()> {
    let location = Location::find_by_id(id)
        .one(db)
        .await?;

    if let Some(location) = location {
        let mut active_model: location::ActiveModel = location.into();
        active_model.tidal_information_last_updated = Set(Some(Utc::now()));
        active_model.update(db).await?;
    }

    Ok(())
}

pub async fn find_for_upcoming_trips(db: &Database) -> anyhow::Result<Vec<location::Model>> {
    let now = Utc::now();
    
    let locations = Location::find()
        .join(JoinType::InnerJoin, location::Relation::Trip.def())
        .filter(trip::Column::EndDate.gt(now))
        .all(db.deref())
        .await?;

    Ok(locations)
}

pub async fn find_coastal_locations_for_upcoming_trips_needing_tidal_update(db: &Database, hours_threshold: i64) -> anyhow::Result<Vec<location::Model>> {
    let threshold_time = Utc::now() - chrono::Duration::hours(hours_threshold);
    let now = Utc::now();
    
    let locations = Location::find()
        .join(JoinType::InnerJoin, location::Relation::Trip.def())
        .filter(trip::Column::EndDate.gt(now))
        .filter(location::Column::IsCoastal.eq(true))
        .filter(
            location::Column::TidalInformationLastUpdated.is_null()
                .or(location::Column::TidalInformationLastUpdated.lt(threshold_time.naive_utc()))
        )
        .all(db.deref())
        .await?;

    Ok(locations)
}

pub async fn delete_by_id(db: &Database, id: Uuid) -> DbResult<()> {
    Location::delete_by_id(id)
        .exec(db.deref())
        .await?;

    Ok(())
}
