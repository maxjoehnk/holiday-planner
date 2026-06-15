use anyhow::Context;
use sea_orm::ActiveValue::Set;
use sea_orm::{DbErr, TransactionTrait};
use uuid::Uuid;
use crate::api::events::{self, DataChangeEvent};
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

#[derive(Copy, Clone, Debug)]
enum ForecastOwner {
    Location { id: Uuid },
    Accommodation { id: Uuid },
}

impl ForecastOwner {
    fn id(&self) -> Uuid {
        match self {
            ForecastOwner::Location { id } | ForecastOwner::Accommodation { id } => *id,
        }
    }
}

impl Job for WeatherSyncJob {
    async fn run(&self) -> anyhow::Result<()> {
        tracing::info!("Running weather sync job");

        let locations_to_update = repositories::locations::find_locations_for_upcoming_trips_needing_weather_update(&self.db, 1).await.context("Fetching locations needing weather data updates")?;
        tracing::info!("Found {} locations needing weather data updates (outdated or missing)", locations_to_update.len());

        for location in locations_to_update {
            tracing::debug!("Fetching forecast for location {} - {}", location.city, location.country);
            let coordinates = Coordinate {
                latitude: location.coordinates_latitude,
                longitude: location.coordinates_longitude,
            };
            if let Err(error) = self
                .sync_forecast(
                    location.trip_id,
                    ForecastOwner::Location { id: location.id },
                    coordinates,
                )
                .await
            {
                tracing::warn!("Weather sync failed for location {}: {:#}", location.id, error);
            }
        }

        let accommodations_to_update = repositories::accommodations::find_for_upcoming_trips_needing_weather_update(&self.db, 1).await.context("Fetching accommodations needing weather data updates")?;
        tracing::info!("Found {} accommodations needing weather data updates", accommodations_to_update.len());

        for accommodation in accommodations_to_update {
            let (Some(latitude), Some(longitude)) = (
                accommodation.coordinates_latitude,
                accommodation.coordinates_longitude,
            ) else {
                continue;
            };
            tracing::debug!("Fetching forecast for accommodation {}", accommodation.name);
            let coordinates = Coordinate { latitude, longitude };
            if let Err(error) = self
                .sync_forecast(
                    accommodation.trip_id,
                    ForecastOwner::Accommodation { id: accommodation.id },
                    coordinates,
                )
                .await
            {
                tracing::warn!(
                    "Weather sync failed for accommodation {}: {:#}",
                    accommodation.id,
                    error
                );
            }
        }

        tracing::info!("Finished weather sync job");
        Ok(())
    }
}

impl WeatherSyncJob {
    async fn sync_forecast(
        &self,
        trip_id: Uuid,
        owner: ForecastOwner,
        coordinates: Coordinate,
    ) -> anyhow::Result<()> {
        let weather = openweathermap::get_forecast(&coordinates).await.context("Fetching forecast")?;
        let forecast = WeatherForecast::from(weather);
        let forecast_id = Uuid::new_v4();
        let (location_id, accommodation_id) = match owner {
            ForecastOwner::Location { id } => (Some(id), None),
            ForecastOwner::Accommodation { id } => (None, Some(id)),
        };
        let active = entities::weather_forecast::ActiveModel {
            id: Set(forecast_id),
            location_id: Set(location_id),
            accommodation_id: Set(accommodation_id),
        };

        self.db
            .transaction::<_, _, DbErr>(|transaction| {
                Box::pin(async move {
                    match owner {
                        ForecastOwner::Location { id } => {
                            repositories::weather_forecasts::remove_forecast_for_location(transaction, id).await?;
                        }
                        ForecastOwner::Accommodation { id } => {
                            repositories::weather_forecasts::remove_forecast_for_accommodation(transaction, id).await?;
                        }
                    }
                    repositories::weather_forecasts::insert_forecast(transaction, active).await?;
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
                    match owner {
                        ForecastOwner::Location { id } => {
                            repositories::locations::update_weather_information_timestamp(transaction, id).await?;
                        }
                        ForecastOwner::Accommodation { id } => {
                            repositories::accommodations::update_weather_information_timestamp(transaction, id).await?;
                        }
                    }
                    Ok(())
                })
            })
            .await
            .context("Updating stored weather information")?;

        events::emit(DataChangeEvent::WeatherUpdated {
            trip_id,
            location_id: owner.id(),
        });

        tracing::debug!("Updated weather information for {:?}", owner);
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
