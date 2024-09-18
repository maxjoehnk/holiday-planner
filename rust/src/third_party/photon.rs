use geojson::GeoJson;

pub async fn search_locations(query: &str) -> anyhow::Result<Vec<geojson::Feature>> {
    let url = format!("https://photon.komoot.io/api/?q={query}");
    let res = reqwest::get(&url).await?;
    let body: GeoJson = res.json()?;

    match body {
        GeoJson::FeatureCollection(collection) => Ok(collection.features),
        _ => Err(anyhow::anyhow!("Expected FeatureCollection")),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_search_locations() {
        let locations = search_locations("Berlin").unwrap();
        assert!(locations.len() > 0);
    }
}
