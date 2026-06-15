use anyhow::Context;
use chrono::{TimeZone, Utc};
use sea_orm::ActiveValue::Set;
use sea_orm::{DbErr, TransactionTrait};
use uuid::Uuid;
use crate::api::events::{self, DataChangeEvent};
use crate::database::enums::PollenType as DbPollenType;
use crate::database::{Database, entities, repositories};
use crate::jobs::Job;
use crate::models::{Coordinate, DailyPollenForecast, PollenForecast, PollenType};
use crate::third_party::google_pollen::{self, GooglePollenForecast};

const HOURS_THRESHOLD: i64 = 6;
const HORIZON_DAYS: i64 = 5;

pub struct PollenSyncJob {
    db: Database,
}

impl PollenSyncJob {
    pub fn new(db: Database) -> Self {
        Self { db }
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

impl Job for PollenSyncJob {
    async fn run(&self) -> anyhow::Result<()> {
        tracing::info!("Running pollen sync job");

        let locations = repositories::locations::find_locations_for_upcoming_trips_needing_pollen_update(&self.db, HOURS_THRESHOLD, HORIZON_DAYS)
            .await
            .context("Fetching locations needing pollen data updates")?;
        tracing::info!("Found {} locations needing pollen data updates", locations.len());

        for location in locations {
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
                tracing::warn!("Pollen sync failed for location {}: {:#}", location.id, error);
            }
        }

        let accommodations = repositories::accommodations::find_for_upcoming_trips_needing_pollen_update(&self.db, HOURS_THRESHOLD, HORIZON_DAYS)
            .await
            .context("Fetching accommodations needing pollen data updates")?;
        tracing::info!("Found {} accommodations needing pollen data updates", accommodations.len());

        for accommodation in accommodations {
            let (Some(latitude), Some(longitude)) = (
                accommodation.coordinates_latitude,
                accommodation.coordinates_longitude,
            ) else {
                continue;
            };
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
                    "Pollen sync failed for accommodation {}: {:#}",
                    accommodation.id,
                    error
                );
            }
        }

        tracing::info!("Finished pollen sync job");
        Ok(())
    }
}

impl PollenSyncJob {
    async fn sync_forecast(
        &self,
        trip_id: Uuid,
        owner: ForecastOwner,
        coordinates: Coordinate,
    ) -> anyhow::Result<()> {
        let response = google_pollen::get_forecast(&coordinates, HORIZON_DAYS as u8)
            .await
            .context("Fetching pollen forecast")?;
        let forecast = PollenForecast::from(response);
        let forecast_id = Uuid::new_v4();
        let (location_id, accommodation_id) = match owner {
            ForecastOwner::Location { id } => (Some(id), None),
            ForecastOwner::Accommodation { id } => (None, Some(id)),
        };
        let active = entities::pollen_forecast::ActiveModel {
            id: Set(forecast_id),
            location_id: Set(location_id),
            accommodation_id: Set(accommodation_id),
        };

        self.db
            .transaction::<_, _, DbErr>(|transaction| {
                Box::pin(async move {
                    match owner {
                        ForecastOwner::Location { id } => {
                            repositories::pollen_forecasts::remove_forecast_for_location(transaction, id).await?;
                        }
                        ForecastOwner::Accommodation { id } => {
                            repositories::pollen_forecasts::remove_forecast_for_accommodation(transaction, id).await?;
                        }
                    }
                    repositories::pollen_forecasts::insert_forecast(transaction, active).await?;
                    for daily in forecast.daily {
                        let mut daily = entities::pollen_daily_forecast::ActiveModel::from(daily);
                        daily.forecast_id = Set(forecast_id);
                        repositories::pollen_forecasts::insert_daily_forecast(transaction, daily).await?;
                    }
                    match owner {
                        ForecastOwner::Location { id } => {
                            repositories::locations::update_pollen_information_timestamp(transaction, id).await?;
                        }
                        ForecastOwner::Accommodation { id } => {
                            repositories::accommodations::update_pollen_information_timestamp(transaction, id).await?;
                        }
                    }
                    Ok(())
                })
            })
            .await
            .context("Updating stored pollen information")?;

        events::emit(DataChangeEvent::PollenUpdated {
            trip_id,
            location_id: owner.id(),
        });

        tracing::debug!("Updated pollen information for {:?}", owner);
        Ok(())
    }
}

impl From<GooglePollenForecast> for PollenForecast {
    fn from(value: GooglePollenForecast) -> Self {
        let mut daily = Vec::new();
        for info in value.daily_info {
            let day = match Utc.with_ymd_and_hms(info.date.year, info.date.month, info.date.day, 0, 0, 0).single() {
                Some(d) => d,
                None => continue,
            };
            for pollen in info.pollen_type_info {
                let Some(pollen_type) = PollenType::from_google_code(&pollen.code) else { continue };
                let Some(index_info) = pollen.index_info else { continue };
                daily.push(DailyPollenForecast {
                    day,
                    pollen_type,
                    index_value: index_info.value,
                    category: index_info.category,
                });
            }
        }
        Self { daily }
    }
}

impl PollenType {
    pub fn from_google_code(code: &str) -> Option<Self> {
        match code {
            "GRASS" => Some(Self::Grass),
            "TREE" => Some(Self::Tree),
            "WEED" => Some(Self::Weed),
            _ => None,
        }
    }
}

impl From<DailyPollenForecast> for entities::pollen_daily_forecast::ActiveModel {
    fn from(value: DailyPollenForecast) -> Self {
        Self {
            day: Set(value.day),
            pollen_type: Set(value.pollen_type.into()),
            index_value: Set(value.index_value),
            category: Set(value.category),
            ..Default::default()
        }
    }
}

impl From<entities::pollen_daily_forecast::Model> for DailyPollenForecast {
    fn from(value: entities::pollen_daily_forecast::Model) -> Self {
        Self {
            day: value.day,
            pollen_type: value.pollen_type.into(),
            index_value: value.index_value,
            category: value.category,
        }
    }
}

impl From<PollenType> for DbPollenType {
    fn from(value: PollenType) -> Self {
        match value {
            PollenType::Grass => DbPollenType::Grass,
            PollenType::Tree => DbPollenType::Tree,
            PollenType::Weed => DbPollenType::Weed,
        }
    }
}

impl From<DbPollenType> for PollenType {
    fn from(value: DbPollenType) -> Self {
        match value {
            DbPollenType::Grass => PollenType::Grass,
            DbPollenType::Tree => PollenType::Tree,
            DbPollenType::Weed => PollenType::Weed,
        }
    }
}
