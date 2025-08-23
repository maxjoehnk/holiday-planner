use anyhow::Context;
use sea_orm::{DbErr, TransactionTrait};
use crate::database::{Database, repositories};
use crate::jobs::Job;
use crate::models::*;
use crate::third_party::world_tides;

pub struct TidalSyncJob {
    db: Database,
}

impl TidalSyncJob {
    pub fn new(db: Database) -> Self {
        Self {
            db,
        }
    }
}

impl Job for TidalSyncJob {
    async fn run(&self) -> anyhow::Result<()> {
        tracing::info!("Running tidal sync job");
        
        let locations_to_update = repositories::locations::find_coastal_locations_for_upcoming_trips_needing_tidal_update(&self.db, 168).await.context("Fetching coastal locations needing tidal data updates")?;
        
        tracing::info!("Found {} coastal locations needing tidal data updates (outdated or missing)", locations_to_update.len());
        
        if locations_to_update.is_empty() {
            tracing::info!("All coastal locations have up-to-date tidal information");
            return Ok(());
        }
        
        for location in locations_to_update {
            tracing::debug!("Fetching tidal data for location {} - {}", location.city, location.country);
            
            let coordinates = Coordinate {
                latitude: location.coordinates_latitude,
                longitude: location.coordinates_longitude,
            };
            
            match world_tides::fetch_tidal_information(&coordinates).await {
                Ok(tide_records) => {
                    let tide_data: Vec<(chrono::DateTime<chrono::Utc>, f64, TideType)> = tide_records
                        .into_iter()
                        .map(|record| (record.date, record.height, record.tide))
                        .collect();

                    self.db.transaction::<_, _, DbErr>(|transaction| {
                        Box::pin(async move {
                            repositories::tidal_information::insert_multiple_tide_records(transaction, location.id, tide_data).await?;

                            repositories::locations::update_tidal_information_timestamp(transaction, location.id).await?;
                            Ok(())
                        })
                    }).await.context("Updating stored tidal information for location")?;

                    tracing::debug!("Updated tidal information for location {}", location.id);
                }
                Err(e) => {
                    tracing::warn!("Failed to fetch tidal information for location {} ({}): {}", 
                        location.city, location.id, e);
                }
            }
        }
        
        tracing::info!("Finished tidal sync job");
        Ok(())
    }
}
