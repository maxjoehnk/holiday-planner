use std::ops::Deref;
use crate::database::entities::{accommodation, trip};
use crate::database::entities::accommodation::Entity as Accommodation;
use sea_orm::{ActiveModelTrait, ColumnTrait, ConnectionTrait, EntityTrait, JoinType, QueryFilter, QueryOrder, QuerySelect, RelationTrait, Set};
use uuid::Uuid;
use chrono::Utc;
use crate::database::{Database, DbResult};

pub async fn find_all_by_trip(db: &Database, trip_id: Uuid) -> anyhow::Result<Vec<accommodation::Model>> {
    let attachments = Accommodation::find()
        .filter(accommodation::Column::TripId.eq(trip_id))
        .order_by_asc(accommodation::Column::Name)
        .all(db.deref())
        .await?;

    Ok(attachments)
}

pub async fn find_by_id(db: &Database, id: Uuid) -> anyhow::Result<Option<accommodation::Model>> {
    let attachment = Accommodation::find_by_id(id)
        .one(db.deref())
        .await?;

    Ok(attachment)
}

pub async fn insert(db: &Database, model: accommodation::ActiveModel) -> anyhow::Result<()> {
    Accommodation::insert(model)
        .exec_without_returning(db.deref())
        .await?;
    
    Ok(())
}

pub async fn update(db: &Database, model: accommodation::ActiveModel) -> anyhow::Result<()> {
    Accommodation::update(model)
        .exec(db.deref())
        .await?;
    
    Ok(())
}

pub async fn delete_by_id(db: &Database, id: Uuid) -> anyhow::Result<()> {
    Accommodation::delete_by_id(id)
        .exec(db.deref())
        .await?;

    Ok(())
}

pub async fn find_for_upcoming_trips_needing_weather_update(
    db: &Database,
    hours_threshold: i64,
) -> anyhow::Result<Vec<accommodation::Model>> {
    let threshold_time = Utc::now() - chrono::Duration::hours(hours_threshold);
    let now = Utc::now();

    let accommodations = Accommodation::find()
        .join(JoinType::InnerJoin, accommodation::Relation::Trip.def())
        .filter(trip::Column::EndDate.gt(now))
        .filter(accommodation::Column::CoordinatesLatitude.is_not_null())
        .filter(accommodation::Column::CoordinatesLongitude.is_not_null())
        .filter(
            accommodation::Column::WeatherInformationLastUpdated
                .is_null()
                .or(accommodation::Column::WeatherInformationLastUpdated
                    .lt(threshold_time.naive_utc())),
        )
        .all(db.deref())
        .await?;

    Ok(accommodations)
}

pub async fn update_weather_information_timestamp(
    db: &impl ConnectionTrait,
    id: Uuid,
) -> DbResult<()> {
    let accommodation = Accommodation::find_by_id(id).one(db).await?;

    if let Some(accommodation) = accommodation {
        let mut active_model: accommodation::ActiveModel = accommodation.into();
        active_model.weather_information_last_updated = Set(Some(Utc::now()));
        active_model.update(db).await?;
    }

    Ok(())
}

pub async fn find_for_upcoming_trips_needing_pollen_update(
    db: &Database,
    hours_threshold: i64,
    horizon_days: i64,
) -> anyhow::Result<Vec<accommodation::Model>> {
    let threshold_time = Utc::now() - chrono::Duration::hours(hours_threshold);
    let now = Utc::now();
    let horizon = now + chrono::Duration::days(horizon_days);

    let accommodations = Accommodation::find()
        .join(JoinType::InnerJoin, accommodation::Relation::Trip.def())
        .filter(trip::Column::EndDate.gt(now))
        .filter(trip::Column::StartDate.lt(horizon))
        .filter(accommodation::Column::CoordinatesLatitude.is_not_null())
        .filter(accommodation::Column::CoordinatesLongitude.is_not_null())
        .filter(
            accommodation::Column::PollenInformationLastUpdated
                .is_null()
                .or(accommodation::Column::PollenInformationLastUpdated
                    .lt(threshold_time.naive_utc())),
        )
        .all(db.deref())
        .await?;

    Ok(accommodations)
}

pub async fn update_pollen_information_timestamp(
    db: &impl ConnectionTrait,
    id: Uuid,
) -> DbResult<()> {
    let accommodation = Accommodation::find_by_id(id).one(db).await?;

    if let Some(accommodation) = accommodation {
        let mut active_model: accommodation::ActiveModel = accommodation.into();
        active_model.pollen_information_last_updated = Set(Some(Utc::now()));
        active_model.update(db).await?;
    }

    Ok(())
}
