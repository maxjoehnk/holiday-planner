use crate::database::Database;
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
    pub fn search_locations(&self, query: String) -> anyhow::Result<Vec<LocationEntry>> {
        tracing::debug!("Searching locations {query}");
        let features = photon::search_locations(&query)?;

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
}

