use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use crate::models::{Coordinates, TidalInformation, TideType};

const API_KEY: Option<&str> = option_env!("WORLD_TIDES_API_KEY");

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct WorldTidesResponse {
    pub status: i32,
    pub call_count: i32,
    #[serde(default)]
    pub heights: Vec<TideHeight>,
    pub extremes: Vec<TideExtreme>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TideHeight {
    pub dt: i64,
    pub date: String,
    pub height: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TideExtreme {
    pub dt: i64,
    pub date: String,
    pub height: f64,
    #[serde(rename = "type")]
    pub tide_type: TideType,
}

pub async fn fetch_tidal_information(coordinates: &Coordinates) -> anyhow::Result<Vec<TidalInformation>> {
    let Some(api_key) = API_KEY else {
        anyhow::bail!("World Tides API key not provided");
    };

    let url = format!(
        "https://www.worldtides.info/api/v3?extremes&lat={}&lon={}&days=7&key={}",
        coordinates.latitude,
        coordinates.longitude,
        api_key
    );
    
    tracing::debug!("Fetching tidal data from: {}", url);
    
    let response = reqwest::get(&url).await?;
    
    if !response.status().is_success() {
        return Err(anyhow::anyhow!("World Tides API request failed with status: {}", response.status()));
    }
    
    let tides_response: WorldTidesResponse = response.json().await?;
    
    if tides_response.status != 200 {
        return Err(anyhow::anyhow!("World Tides API returned error status: {}", tides_response.status));
    }
    
    // Convert extremes to individual tide records
    let tide_records: Vec<TidalInformation> = tides_response.extremes
        .into_iter()
        .map(|extreme| TidalInformation {
            date: DateTime::from_timestamp(extreme.dt, 0)
                .unwrap_or_else(|| Utc::now()),
            height: extreme.height,
            tide: extreme.tide_type,
        })
        .collect();
    
    Ok(tide_records)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    #[ignore] // Requires API key
    async fn test_fetch_tidal_information() {
        let coordinates = Coordinates {
            latitude: 51.5074,
            longitude: -0.1278,
        };
        
        // This test requires a valid API key
        let api_key = std::env::var("WORLD_TIDES_API_KEY").unwrap_or_default();
        if api_key.is_empty() {
            println!("Skipping test - no API key provided");
            return;
        }
        
        let result = fetch_tidal_information(&coordinates).await;
        assert!(result.is_ok());
        
        let tide_records = result.unwrap();
        println!("Tide records: {:?}", tide_records);
        assert!(!tide_records.is_empty());
    }
}
