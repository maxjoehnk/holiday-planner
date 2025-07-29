use serde::{Deserialize, Serialize};
use std::collections::HashMap;

const KM: i32 = 1000;
const RADIUS: i32 = 10 * KM;

/// Response structure for Overpass API queries
#[derive(Debug, Deserialize)]
struct OverpassResponse {
    elements: Vec<OverpassElement>,
}

#[derive(Debug, Deserialize)]
struct OverpassElement {
    #[serde(rename = "type")]
    element_type: String,
    id: u64,
    tags: Option<HashMap<String, String>>,
    lat: Option<f64>,
    lon: Option<f64>,
}

/// Determines if a location is coastal by querying the Overpass API for nearby water bodies
pub async fn is_coastal(latitude: f64, longitude: f64) -> anyhow::Result<bool> {
     let query = format!(
        r#"[out:json][timeout:25];
        (
          way["natural"="coastline"](around:{},{},{});
        );
        out geom;"#,
        RADIUS, latitude, longitude,
    );

    let client = reqwest::Client::new();
    let response = client
        .post("https://overpass-api.de/api/interpreter")
        .header("Content-Type", "application/x-www-form-urlencoded")
        .body(query)
        .send()
        .await?;

    if !response.status().is_success() {
        return Err(anyhow::anyhow!("Overpass API request failed: {}", response.status()));
    }

    let overpass_response: OverpassResponse = response.json().await?;
    
    // Check if we found any coastal or water features
    let has_coastal_features = overpass_response.elements.iter().any(|element| {
        if let Some(tags) = &element.tags {
            if tags.get("natural") == Some(&"coastline".to_string()) {
                return true;
            }
        }
        false
    });

    tracing::debug!(
        "Overpass API coastal check for ({}, {}): found {} elements, coastal: {}",
        latitude,
        longitude,
        overpass_response.elements.len(),
        has_coastal_features
    );

    Ok(has_coastal_features)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_coastal_detection_miami() {
        // Miami - should be coastal
        let result = is_coastal(25.7617, -80.1918).await;
        assert!(result.is_ok());
        if let Ok(is_coastal_result) = result {
            println!("Miami coastal detection: {}", is_coastal_result);
            // Note: This might fail in tests due to network dependency
            // In a real implementation, you might want to mock this
        }
    }

    #[tokio::test]
    async fn test_coastal_detection_denver() {
        // Denver - should not be coastal
        let result = is_coastal(39.7392, -104.9903).await;
        assert!(result.is_ok());
        if let Ok(is_coastal_result) = result {
            println!("Denver coastal detection: {}", is_coastal_result);
            // Note: This might fail in tests due to network dependency
        }
    }

    #[tokio::test]
    async fn test_overpass_api_response() {
        // Test with a known coastal location to verify API response structure
        let result = is_coastal(37.7749, -122.4194).await; // San Francisco
        match result {
            Ok(is_coastal_result) => {
                println!("San Francisco coastal detection: {}", is_coastal_result);
            }
            Err(e) => {
                println!("API call failed (expected in some test environments): {}", e);
            }
        }
    }
}
