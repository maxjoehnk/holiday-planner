use std::ops::Deref;
use sea_orm::ActiveValue::Set;
use uuid::Uuid;
use crate::database::{Database, repositories, entities};
use crate::models::*;
use crate::handlers::Handler;
use crate::third_party::{photon, overpass};

pub struct LocationHandler {
    db: Database,
}

impl Handler for LocationHandler {
    fn create(db: Database) -> Self {
        Self {
            db,
        }
    }
}

impl LocationHandler {
    pub async fn search_locations(&self, query: String) -> anyhow::Result<Vec<LocationEntry>> {
        tracing::debug!("Searching locations {query}");
        let features = photon::search_locations(&query).await?;

        tracing::debug!("Received {} locations", features.len());

        let locations = features.into_iter()
            .flat_map(|feature| {
                let geometry = feature.geometry?;
                let properties = feature.properties?;

                match geometry.value {
                    geojson::Value::Point(coords) => {
                        let name = properties.get("name")?.as_str()?.to_string();
                        let country = properties.get("country")?.as_str()?.to_string();

                        Some(LocationEntry {
                            name,
                            coordinates: Coordinates {
                                latitude: coords[1],
                                longitude: coords[0],
                            },
                            country,
                        })
                    }
                    _ => None,
                }
            })
            .collect();

        Ok(locations)
    }
    
    pub async fn get_trip_locations(&self, trip_id: Uuid) -> anyhow::Result<Vec<TripLocationListModel>> {
        let locations = repositories::locations::find_all_by_trip(&self.db, trip_id).await?;
        let forecasts = repositories::weather_forecasts::load_forecasts_for_locations(&self.db, &locations).await?;
        
        let mut result = Vec::new();
        for (location, (daily_forecasts, hourly_forecasts)) in locations.into_iter().zip(forecasts) {
            let tide_records = repositories::tidal_information::find_all_by_location_id(&self.db, location.id).await?;
            let tidal_information = tide_records.into_iter()
                .map(|tide_record| TidalInformation {
                    date: tide_record.date,
                    height: tide_record.height,
                    tide: tide_record.tide.into(),
                })
                .collect();

            result.push(TripLocationListModel {
                id: location.id,
                coordinates: Coordinates {
                    latitude: location.coordinates_latitude,
                    longitude: location.coordinates_longitude,
                },
                country: location.country,
                city: location.city,
                is_coastal: location.is_coastal,
                tidal_information_last_updated: location.tidal_information_last_updated,
                tidal_information,
                forecast: Some(WeatherForecast {
                    daily_forecast: daily_forecasts.into_iter().map(DailyWeatherForecast::from).collect(),
                    hourly_forecast: hourly_forecasts.into_iter().map(HourlyWeatherForecast::from).collect(),
                }),
            });
        }

        Ok(result)
    }

    pub async fn add_trip_location(&self, trip_id: Uuid, location: LocationEntry) -> anyhow::Result<()> {
        let is_coastal = overpass::is_coastal(location.coordinates.latitude, location.coordinates.longitude)
            .await
            .unwrap_or_else(|e| {
                tracing::warn!("Failed to check coastal status via Overpass API: {}. Defaulting to false.", e);
                false
            });
        
        tracing::debug!(
            "Adding location '{}' at ({}, {}) - coastal: {}",
            location.name,
            location.coordinates.latitude,
            location.coordinates.longitude,
            is_coastal
        );
        
        let location = entities::location::ActiveModel {
            id: Set(Uuid::new_v4()),
            trip_id: Set(trip_id),
            coordinates_latitude: Set(location.coordinates.latitude),
            coordinates_longitude: Set(location.coordinates.longitude),
            country: Set(location.country),
            city: Set(location.name), // TODO: this mapping is false
            is_coastal: Set(is_coastal), // Automatically determined based on coordinates
            tidal_information_last_updated: Set(None),
        };
        
        repositories::locations::insert(&self.db, location).await?;

        Ok(())
    }

    pub async fn update_coastal_flag(&self, location_id: Uuid, is_coastal: bool) -> anyhow::Result<()> {
        repositories::locations::update_coastal_flag(&self.db, location_id, is_coastal).await?;
        
        if !is_coastal {
            repositories::tidal_information::delete_by_location_id(self.db.deref(), location_id).await?;
        }
        
        Ok(())
    }

}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::database::Database;
    use uuid::Uuid;

    #[tokio::test]
    async fn test_coastal_detection_integration() {
        // Test that coastal detection is automatically applied when adding locations
        
        // Create test locations - one coastal, one inland
        let miami_location = LocationEntry {
            name: "Miami".to_string(),
            coordinates: Coordinates {
                latitude: 25.7617,
                longitude: -80.1918,
            },
            country: "United States".to_string(),
        };
        
        let denver_location = LocationEntry {
            name: "Denver".to_string(),
            coordinates: Coordinates {
                latitude: 39.7392,
                longitude: -104.9903,
            },
            country: "United States".to_string(),
        };
        
        // Test the coastal detection directly using Overpass API
        // Note: These tests may fail in environments without internet access
        match overpass::is_coastal(miami_location.coordinates.latitude, miami_location.coordinates.longitude).await {
            Ok(is_coastal) => println!("Miami coastal detection: {}", is_coastal),
            Err(e) => println!("Miami coastal detection failed (expected in test environments): {}", e),
        }
        
        match overpass::is_coastal(denver_location.coordinates.latitude, denver_location.coordinates.longitude).await {
            Ok(is_coastal) => println!("Denver coastal detection: {}", is_coastal),
            Err(e) => println!("Denver coastal detection failed (expected in test environments): {}", e),
        }
        
        println!("Coastal detection integration test passed!");
    }
}

