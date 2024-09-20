use std::ops::Deref;
use sea_orm::{EntityTrait, ColumnTrait, QueryFilter, LoaderTrait, ModelTrait, ConnectionTrait};
use crate::database::entities::location;
use crate::database::entities::weather_forecast::{self, Entity as WeatherForecast};
use crate::database::entities::weather_daily_forecast::{self, Entity as WeatherDailyForecast};
use crate::database::entities::weather_hourly_forecast::{self, Entity as WeatherHourlyForecast};
use crate::database::{Database, DbResult};

pub async fn load_forecasts_for_locations(db: &Database, locations: &Vec<location::Model>) -> DbResult<Vec<(Vec<weather_daily_forecast::Model>, Vec<weather_hourly_forecast::Model>)>> {
    let forecasts = locations.load_one(WeatherForecast, db.deref()).await?;
    let mut result = Vec::with_capacity(locations.len());
    for forecast in forecasts {
        if let Some(forecast) = forecast {
            let daily_forecasts = forecast.find_related(WeatherDailyForecast).all(db.deref()).await?;
            let hourly_forecasts = forecast.find_related(WeatherHourlyForecast).all(db.deref()).await?;
            result.push((daily_forecasts, hourly_forecasts));
        }else {
            result.push((Vec::new(), Vec::new()));
        }
    }
    
    Ok(result)
}

pub async fn remove_forecast_for_location(db: &impl ConnectionTrait, location_id: uuid::Uuid) -> DbResult<()> {
    WeatherForecast::delete_many()
        .filter(weather_forecast::Column::LocationId.eq(location_id))
        .exec(db)
        .await?;

    Ok(())
}

pub async fn insert_forecast(db: &impl ConnectionTrait, forecast: weather_forecast::ActiveModel) -> DbResult<()> {
    WeatherForecast::insert(forecast)
        .exec_without_returning(db)
        .await?;

    Ok(())
}

pub async fn insert_daily_forecast(db: &impl ConnectionTrait, forecast: weather_daily_forecast::ActiveModel) -> DbResult<()> {
    WeatherDailyForecast::insert(forecast)
        .exec_without_returning(db)
        .await?;

    Ok(())
}

pub async fn insert_hourly_forecast(db: &impl ConnectionTrait, forecast: weather_hourly_forecast::ActiveModel) -> DbResult<()> {
    WeatherHourlyForecast::insert(forecast)
        .exec_without_returning(db)
        .await?;

    Ok(())
}
