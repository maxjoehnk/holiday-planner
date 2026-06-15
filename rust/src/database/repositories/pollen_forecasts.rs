use std::ops::Deref;
use sea_orm::{EntityTrait, ColumnTrait, QueryFilter, LoaderTrait, ModelTrait, ConnectionTrait};
use crate::database::entities::{accommodation, location};
use crate::database::entities::pollen_forecast::{self, Entity as PollenForecast};
use crate::database::entities::pollen_daily_forecast::{self, Entity as PollenDailyForecast};
use crate::database::{Database, DbResult};

pub async fn load_forecasts_for_locations(db: &Database, locations: &Vec<location::Model>) -> DbResult<Vec<Vec<pollen_daily_forecast::Model>>> {
    let forecasts = locations.load_one(PollenForecast, db.deref()).await?;
    let mut result = Vec::with_capacity(locations.len());
    for forecast in forecasts {
        if let Some(forecast) = forecast {
            let daily_forecasts = forecast.find_related(PollenDailyForecast).all(db.deref()).await?;
            result.push(daily_forecasts);
        } else {
            result.push(Vec::new());
        }
    }

    Ok(result)
}

pub async fn load_forecasts_for_accommodations(
    db: &Database,
    accommodations: &Vec<accommodation::Model>,
) -> DbResult<Vec<Vec<pollen_daily_forecast::Model>>> {
    let forecasts = accommodations.load_one(PollenForecast, db.deref()).await?;
    let mut result = Vec::with_capacity(accommodations.len());
    for forecast in forecasts {
        if let Some(forecast) = forecast {
            let daily_forecasts = forecast.find_related(PollenDailyForecast).all(db.deref()).await?;
            result.push(daily_forecasts);
        } else {
            result.push(Vec::new());
        }
    }
    Ok(result)
}

pub async fn remove_forecast_for_location(db: &impl ConnectionTrait, location_id: uuid::Uuid) -> DbResult<()> {
    PollenForecast::delete_many()
        .filter(pollen_forecast::Column::LocationId.eq(location_id))
        .exec(db)
        .await?;

    Ok(())
}

pub async fn remove_forecast_for_accommodation(db: &impl ConnectionTrait, accommodation_id: uuid::Uuid) -> DbResult<()> {
    PollenForecast::delete_many()
        .filter(pollen_forecast::Column::AccommodationId.eq(accommodation_id))
        .exec(db)
        .await?;

    Ok(())
}

pub async fn insert_forecast(db: &impl ConnectionTrait, forecast: pollen_forecast::ActiveModel) -> DbResult<()> {
    PollenForecast::insert(forecast)
        .exec_without_returning(db)
        .await?;

    Ok(())
}

pub async fn insert_daily_forecast(db: &impl ConnectionTrait, forecast: pollen_daily_forecast::ActiveModel) -> DbResult<()> {
    PollenDailyForecast::insert(forecast)
        .exec_without_returning(db)
        .await?;

    Ok(())
}
