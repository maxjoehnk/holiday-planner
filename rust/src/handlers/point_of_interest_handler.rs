use geojson::JsonObject;
use sea_orm::ActiveValue::Set;
use sea_orm::IntoActiveModel;
use uuid::Uuid;
use crate::commands::{AddTripPointOfInterest, UpdateTripPointOfInterest};
use crate::database::{Database, entities, repositories};
use crate::handlers::Handler;
use crate::models::{Coordinate, PointOfInterestModel};
use crate::models::point_of_interests::{PointOfInterestOsmModel, PointOfInterestSearchModel};
use crate::third_party::{overpass, photon};

pub struct PointOfInterestHandler {
    db: Database,
}

impl Handler for PointOfInterestHandler {
    fn create(db: Database) -> Self {
        Self {
            db,
        }
    }
}

impl PointOfInterestHandler {
    pub async fn search_point_of_interest(&self, trip_id: Uuid, name: String) -> anyhow::Result<Vec<PointOfInterestSearchModel>> {
        let locations = repositories::locations::find_all_by_trip(&self.db, trip_id).await?;
        let locations = locations.into_iter()
            .map(|l| Coordinate {
                longitude: l.coordinates_longitude,
                latitude: l.coordinates_latitude,
            })
            .collect();

        let pois = photon::search_points_of_interest(&name, locations, None).await?;
        let pois = pois.into_iter()
            .flat_map(|feature| {
                tracing::debug!("Found point of interest: {feature:?}");
                let geometry = feature.geometry?;
                let properties = feature.properties?;

                match geometry.value {
                    geojson::Value::Point(coords) => {
                        let id = properties.get("osm_id")?.as_i64()? as u64;
                        let name = properties.get("name")?.as_str()?.to_string();
                        let country = properties.get("country")?.as_str()?.to_string();

                        Some(PointOfInterestSearchModel {
                            id,
                            name,
                            country,
                            address: get_address(&properties),
                            coordinate: Some(Coordinate {
                                latitude: coords[1],
                                longitude: coords[0],
                            }),
                        })
                    }
                    _ => None,
                }
            })
            .collect();

        Ok(pois)
    }

    pub async fn search_point_of_interest_details(&self, id: u64) -> anyhow::Result<PointOfInterestOsmModel> {
        let tags = overpass::get_point_of_interest_data(id).await?;
        // TODO: other formatting of PH for public holidays
        let opening_hours = tags.get("opening_hours").cloned();
        let website = tags.get("website").cloned();
        let phone_number = tags.get("phone").cloned();

        Ok(PointOfInterestOsmModel {
            id,
            opening_hours,
            website,
            phone_number,
        })
    }

    pub async fn add_point_of_interest(&self, command: AddTripPointOfInterest) -> anyhow::Result<()> {
        tracing::debug!("Adding point of interest to trip {}", command.trip_id);
        
        let point_of_interest = entities::point_of_interest::ActiveModel {
            id: Set(Uuid::new_v4()),
            trip_id: Set(command.trip_id),
            name: Set(command.name),
            address: Set(command.address),
            website: Set(command.website),
            opening_hours: Set(command.opening_hours),
            price: Set(command.price),
            phone_number: Set(command.phone_number),
            note: Set(command.note),
            coordinates_latitude: Set(command.coordinate.map(|c| c.latitude)),
            coordinates_longitude: Set(command.coordinate.map(|c| c.longitude)),
        };
        
        repositories::points_of_interest::insert(&self.db, point_of_interest).await?;

        Ok(())
    }
    
    pub async fn get_trip_points_of_interest(&self, trip_id: Uuid) -> anyhow::Result<Vec<PointOfInterestModel>> {
        let points_of_interest = repositories::points_of_interest::find_all_by_trip(&self.db, trip_id).await?;
        let points_of_interest = points_of_interest.into_iter().map(|p| PointOfInterestModel {
            trip_id: p.trip_id,
            id: p.id,
            name: p.name,
            address: p.address,
            website: p.website,
            opening_hours: p.opening_hours,
            coordinates: p.coordinates_longitude.zip(p.coordinates_latitude).map(|(longitude, latitude)| Coordinate {
                longitude,
                latitude,
            }),
            price: p.price,
            phone_number: p.phone_number,
            note: p.note,
        }).collect();
        
        Ok(points_of_interest)
    }

    pub async fn update_point_of_interest(&self, command: UpdateTripPointOfInterest) -> anyhow::Result<()> {
        let Some(point_of_interest) = repositories::points_of_interest::find_by_id(&self.db, command.id).await? else {
            anyhow::bail!("Unknown point of interest");
        };
        let mut point_of_interest = point_of_interest.into_active_model();
        point_of_interest.name.set_if_not_equals(command.name);
        point_of_interest.address.set_if_not_equals(command.address);
        point_of_interest.website.set_if_not_equals(command.website);
        point_of_interest.opening_hours.set_if_not_equals(command.opening_hours);
        point_of_interest.price.set_if_not_equals(command.price);
        point_of_interest.phone_number.set_if_not_equals(command.phone_number);
        point_of_interest.note.set_if_not_equals(command.note);
        point_of_interest.coordinates_latitude.set_if_not_equals(command.coordinate.map(|c| c.latitude));
        point_of_interest.coordinates_longitude.set_if_not_equals(command.coordinate.map(|c| c.longitude));

        repositories::points_of_interest::update(&self.db, point_of_interest).await?;

        Ok(())
    }

    pub async fn delete_point_of_interest(&self, point_of_interest_id: Uuid) -> anyhow::Result<()> {
        repositories::points_of_interest::delete_by_id(&self.db, point_of_interest_id).await?;

        Ok(())
    }
}

fn get_address(properties: &JsonObject) -> Option<String> {
    let housenumber = properties.get("housenumber").and_then(|v| v.as_str());
    let street = properties.get("street").and_then(|v| v.as_str());
    let city = properties.get("city").and_then(|v| v.as_str());
    let postcode = properties.get("postcode").and_then(|v| v.as_str());

    let mut address_section = String::new();
    let mut city_section = String::new();
    if let Some(street) = street {
        address_section.push_str(street);
    }
    if let Some(housenumber) = housenumber {
        if !address_section.is_empty() {
            address_section.push(' ');
        }
        address_section.push_str(housenumber);
    }
    if let Some(postcode) = postcode {
        city_section.push_str(postcode);
    }
    if let Some(city) = city {
        if !city_section.is_empty() {
            city_section.push(' ');
        }
        city_section.push_str(city);
    }

    if address_section.is_empty() && city_section.is_empty() {
        None
    } else if address_section.is_empty() {
        Some(city_section)
    } else if city_section.is_empty() {
        Some(address_section)
    } else {
        Some(format!("{}, {}", address_section, city_section))
    }
}

#[cfg(test)]
mod tests {
    use geojson::JsonObject;
    use geojson::JsonValue;

    fn build_properties(housenumber: Option<&str>, street: Option<&str>, city: Option<&str>, postcode: Option<&str>) -> JsonObject {
        let mut properties = JsonObject::new();
        if let Some(housenumber) = housenumber {
            properties.insert("housenumber".to_string(), JsonValue::String(housenumber.to_string()));
        }
        if let Some(street) = street {
            properties.insert("street".to_string(), JsonValue::String(street.to_string()));
        }
        if let Some(city) = city {
            properties.insert("city".to_string(), JsonValue::String(city.to_string()));
        }
        if let Some(postcode) = postcode {
            properties.insert("postcode".to_string(), JsonValue::String(postcode.to_string()));
        }
        properties
    }

    #[test]
    fn get_address_should_return_full_address() {
        let properties = build_properties(Some("123"), Some("Main Street"), Some("Berlin"), Some("10115"));

        let address = super::get_address(&properties);

        assert_eq!(address, Some("Main Street 123, 10115 Berlin".to_string()));
    }

    #[test]
    fn get_address_should_return_only_street() {
        let properties = build_properties(Some("4b"), Some("Side Street"), None, None);

        let address = super::get_address(&properties);

        assert_eq!(address, Some("Side Street 4b".to_string()));
    }
}
