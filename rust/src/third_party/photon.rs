use geojson::GeoJson;

pub async fn search_locations(query: &str) -> anyhow::Result<Vec<geojson::Feature>> {
    let url = format!("https://photon.komoot.io/api/?q={query}");
    let res = reqwest::get(&url).await?;
    let body: GeoJson = res.json().await?;

    match body {
        GeoJson::FeatureCollection(collection) => Ok(collection.features),
        _ => Err(anyhow::anyhow!("Expected FeatureCollection")),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_search_locations() {
        let locations = search_locations("Berlin").await.unwrap();
        println!("{locations:?}");
        assert!(!locations.is_empty());
    }

    #[tokio::test]
    async fn test_coastal_cities() {
        let coastal_cities = vec!["Miami", "Barcelona", "Venice", "San Francisco"];
        
        for city in coastal_cities {
            println!("\n=== Testing {} ===", city);
            let locations = search_locations(city).await.unwrap();
            
            if let Some(first_location) = locations.first() {
                if let Some(properties) = &first_location.properties {
                    println!("Properties for {}: {:#?}", city, properties);
                }
            }
        }
    }

}
