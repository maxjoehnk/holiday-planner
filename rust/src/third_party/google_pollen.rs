use serde::Deserialize;

use crate::models::Coordinate;

const API_KEY: Option<&str> = option_env!("GOOGLE_POLLEN_API_KEY");
const MAX_FORECAST_DAYS: u8 = 5;

pub async fn get_forecast(coordinates: &Coordinate, days: u8) -> anyhow::Result<GooglePollenForecast> {
    let Some(key) = API_KEY else {
        anyhow::bail!("GOOGLE_POLLEN_API_KEY is not set");
    };
    let days = days.clamp(1, MAX_FORECAST_DAYS);
    let url = format!(
        "https://pollen.googleapis.com/v1/forecast:lookup?key={}&location.latitude={}&location.longitude={}&days={}&plantsDescription=false&languageCode=en",
        key, coordinates.latitude, coordinates.longitude, days,
    );
    let res = reqwest::get(&url).await?;
    if !res.status().is_success() {
        let status = res.status();
        let body = res.text().await.unwrap_or_default();
        anyhow::bail!("Google Pollen API returned {}: {}", status, body);
    }
    let body: GooglePollenForecast = res.json().await?;

    Ok(body)
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GooglePollenForecast {
    #[serde(default)]
    pub daily_info: Vec<DailyInfo>,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DailyInfo {
    pub date: GoogleDate,
    #[serde(default)]
    pub pollen_type_info: Vec<PollenTypeInfo>,
}

#[derive(Debug, Clone, Copy, Deserialize)]
pub struct GoogleDate {
    pub year: i32,
    pub month: u32,
    pub day: u32,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PollenTypeInfo {
    pub code: String,
    #[serde(default)]
    pub in_season: Option<bool>,
    #[serde(default)]
    pub index_info: Option<IndexInfo>,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct IndexInfo {
    #[serde(default)]
    pub value: i32,
    #[serde(default)]
    pub category: Option<String>,
}
