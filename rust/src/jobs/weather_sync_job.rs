use anyhow::Context;
use sea_orm::ActiveValue::Set;
use sea_orm::{DbErr, TransactionTrait};
use crate::database::{Database, repositories, entities};
use crate::jobs::Job;
use crate::models::{Coordinate, DailyWeatherForecast, HourlyWeatherForecast, WeatherForecast};
use crate::third_party::openweathermap;

pub struct WeatherSyncJob {
    db: Database,
}

impl WeatherSyncJob {
    pub fn new(db: Database) -> Self {
        Self {
            db,
        }
    }
}

impl Job for WeatherSyncJob {
    async fn run(&self) -> anyhow::Result<()> {
        tracing::info!("Running weather sync job");
        
        let locations_to_update = repositories::locations::find_locations_for_upcoming_trips_needing_weather_update(&self.db, 1).await.context("Fetching locations needing weather data updates")?;
        
        tracing::info!("Found {} locations needing weather data updates (outdated or missing)", locations_to_update.len());
        
        if locations_to_update.is_empty() {
            tracing::info!("All locations have up-to-date weather information");
            return Ok(());
        }
        
        for location in locations_to_update {
            tracing::debug!("Fetching forecast for location {} - {}", location.city, location.country);
            let coordinates = Coordinate {
                latitude: location.coordinates_latitude,
                longitude: location.coordinates_longitude,
            };
            let weather = openweathermap::get_forecast(&coordinates).await.context("Fetching forecast")?;
            let forecast = WeatherForecast::from(weather);
            let forecast_id = uuid::Uuid::new_v4();
            let location_forecast = entities::weather_forecast::ActiveModel {
                location_id: Set(location.id),
                id: Set(forecast_id),
            };
            self.db.transaction::<_, _, DbErr>(|transaction| {
                Box::pin(async move {
                    repositories::weather_forecasts::remove_forecast_for_location(transaction, location.id).await?;
                    repositories::weather_forecasts::insert_forecast(transaction, location_forecast).await?;
                    for daily in forecast.daily_forecast {
                        let mut daily = entities::weather_daily_forecast::ActiveModel::from(daily);
                        daily.forecast_id = Set(forecast_id);
                        repositories::weather_forecasts::insert_daily_forecast(transaction, daily).await?;
                    }
                    for hourly in forecast.hourly_forecast {
                        let mut hourly = entities::weather_hourly_forecast::ActiveModel::from(hourly);
                        hourly.forecast_id = Set(forecast_id);
                        repositories::weather_forecasts::insert_hourly_forecast(transaction, hourly).await?;
                    }

                    repositories::locations::update_weather_information_timestamp(transaction, location.id).await?;
                    Ok(())
                })
            }).await.context("Updating stored weather information for location")?;

            tracing::debug!("Updated weather information for location {}", location.id);
        }
        tracing::info!("Finished weather sync job");

        Ok(())
    }
}

impl From<DailyWeatherForecast> for entities::weather_daily_forecast::ActiveModel {
    fn from(value: DailyWeatherForecast) -> Self {
        Self {
            day: Set(value.day),
            min_temperature: Set(value.min_temperature),
            max_temperature: Set(value.max_temperature),
            morning_temperature: Set(value.morning_temperature),
            day_temperature: Set(value.day_temperature),
            evening_temperature: Set(value.evening_temperature),
            night_temperature: Set(value.night_temperature),
            condition: Set(value.condition.into()),
            precipitation_amount: Set(value.precipitation_amount),
            precipitation_probability: Set(value.precipitation_probability),
            wind_speed: Set(value.wind_speed),
            ..Default::default()
        }
    }
}

impl From<entities::weather_daily_forecast::Model> for DailyWeatherForecast {
    fn from(value: entities::weather_daily_forecast::Model) -> Self {
        Self {
            day: value.day,
            min_temperature: value.min_temperature,
            max_temperature: value.max_temperature,
            morning_temperature: value.morning_temperature,
            day_temperature: value.day_temperature,
            evening_temperature: value.evening_temperature,
            night_temperature: value.night_temperature,
            condition: value.condition.into(),
            precipitation_amount: value.precipitation_amount,
            precipitation_probability: value.precipitation_probability,
            wind_speed: value.wind_speed,
        }
    }
}

impl From<HourlyWeatherForecast> for entities::weather_hourly_forecast::ActiveModel {
    fn from(value: HourlyWeatherForecast) -> Self {
        Self {
            time: Set(value.time),
            temperature: Set(value.temperature),
            wind_speed: Set(value.wind_speed),
            precipitation_amount: Set(value.precipitation_amount),
            precipitation_probability: Set(value.precipitation_probability),
            condition: Set(value.condition.into()),
            ..Default::default()
        }
    }
}

impl From<entities::weather_hourly_forecast::Model> for HourlyWeatherForecast {
    fn from(value: entities::weather_hourly_forecast::Model) -> Self {
        Self {
            time: value.time,
            temperature: value.temperature,
            wind_speed: value.wind_speed,
            precipitation_amount: value.precipitation_amount,
            precipitation_probability: value.precipitation_probability,
            condition: value.condition.into(),
        }
    }
}
