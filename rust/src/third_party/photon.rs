use geojson::GeoJson;
use crate::models::Coordinate;

pub async fn search_cities(query: &str) -> anyhow::Result<Vec<geojson::Feature>> {
    let url = format!("https://photon.komoot.io/api/?q={query}&layer=city&layer=district&layer=locality");
    let res = reqwest::get(&url).await?;
    let body: GeoJson = res.json().await?;

    match body {
        GeoJson::FeatureCollection(collection) => Ok(collection.features),
        _ => Err(anyhow::anyhow!("Expected FeatureCollection")),
    }
}

pub async fn search_points_of_interest(query: &str, locations: Vec<Coordinate>, limit: Option<usize>) -> anyhow::Result<Vec<geojson::Feature>> {
    let limit = limit.unwrap_or(10);
    let url = format!("https://photon.komoot.io/api/?q={query}&layer=house&layer=other&limit={limit}");
    let url = match locations.len() {
        1 => {
            let loc = &locations[0];
            format!("{url}&lat={}&lon={}", loc.latitude, loc.longitude)
        },
        // TODO: should we run multiple queries for multiple locations? calculating a bounding box would maybe work as well or we have to change to the overpass api?
        _ => url,
    };

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
    async fn test_search_cities() {
        let locations = search_cities("Berlin").await.unwrap();
        println!("{locations:?}");
        assert!(!locations.is_empty());
    }

    #[tokio::test]
    async fn test_search_points_of_interests() {
        let locations = search_points_of_interest("Universum", Default::default(), Some(1)).await.unwrap();
        println!("{locations:?}");
        assert_eq!(locations.len(), 1);
    }
}
