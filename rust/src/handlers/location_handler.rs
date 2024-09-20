use sea_orm::ActiveValue::Set;
use uuid::Uuid;
use crate::database::{Database, repositories, entities};
use crate::models::*;
use crate::handlers::Handler;
use crate::third_party::photon;


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
        let locations = locations.into_iter().zip(forecasts).map(|(location, (daily_forecasts, hourly_forecasts))| TripLocationListModel {
            id: location.id,
            coordinates: Coordinates {
                latitude: location.coordinates_latitude,
                longitude: location.coordinates_longitude,
            },
            country: location.country,
            city: location.city,
            forecast: Some(WeatherForecast {
                daily_forecast: daily_forecasts.into_iter().map(DailyWeatherForecast::from).collect(),
                hourly_forecast: hourly_forecasts.into_iter().map(HourlyWeatherForecast::from).collect(),
            }),
        }).collect();

        Ok(locations)
    }

    pub async fn add_trip_location(&self, trip_id: Uuid, location: LocationEntry) -> anyhow::Result<()> {
        let location = entities::location::ActiveModel {
            id: Set(Uuid::new_v4()),
            trip_id: Set(trip_id),
            coordinates_latitude: Set(location.coordinates.latitude),
            coordinates_longitude: Set(location.coordinates.longitude),
            country: Set(location.country),
            city: Set(location.name), // TODO: this mapping is false
        };
        
        repositories::locations::insert(&self.db, location).await?;

        Ok(())
    }
}

