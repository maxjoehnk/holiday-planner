use chrono::TimeZone;
use serde::Deserialize;

use crate::models::{Coordinates, DailyWeatherForecast, HourlyWeatherForecast, WeatherCondition, WeatherForecast};

const API_KEY: &str = env!("OPENWEATHERMAP_API_KEY");

pub fn get_forecast(coordinates: &Coordinates) -> anyhow::Result<OpenWeatherMap> {
    let url = format!("https://api.openweathermap.org/data/3.0/onecall?lat={}&lon={}&appid={}&exclude=current,minutely,alerts&units=metric", coordinates.latitude, coordinates.longitude, API_KEY);
    let res = reqwest::blocking::get(&url)?;
    let body: OpenWeatherMap = res.json()?;

    Ok(body)
}

#[derive(Debug, Clone, Deserialize)]
pub struct OpenWeatherMap {
    hourly: Vec<OWHourly>,
    daily: Vec<OWDaily>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct OWCurrent {
    #[serde(rename = "dt")]
    pub current_time: u64,
    pub sunrise: u64,
    pub sunset: u64,
    #[serde(rename = "temp")]
    pub temperature: f64,
    #[serde(rename = "uvi")]
    pub uv_index: f64,
    pub wind_speed: f64,
    pub weather: Vec<OWMWeatherCondition>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct OWHourly {
    #[serde(rename = "dt")]
    pub current_time: u64,
    #[serde(rename = "temp")]
    pub temperature: f64,
    #[serde(rename = "uvi")]
    pub uv_index: f64,
    pub wind_speed: f64,
    pub weather: Vec<OWMWeatherCondition>,
    pub rain: f64,
    #[serde(rename = "pop")]
    pub precipitation_probability: f64,
}

#[derive(Debug, Clone, Deserialize)]
pub struct OWDaily {
    #[serde(rename = "dt")]
    pub current_time: u64,
    pub sunrise: u64,
    pub sunset: u64,
    #[serde(rename = "temp")]
    pub temperature: OWTemperature,
    #[serde(rename = "uvi")]
    pub uv_index: f64,
    pub wind_speed: f64,
    pub weather: Vec<OWMWeatherCondition>,
    pub rain: f64,
    #[serde(rename = "pop")]
    pub precipitation_probability: f64,
    pub summary: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct OWTemperature {
    pub morn: f64,
    pub day: f64,
    pub eve: f64,
    pub night: f64,
    pub min: f64,
    pub max: f64,
}

#[derive(Debug, Clone, Deserialize)]
pub struct OWMWeatherCondition {
    pub id: u32,
    pub main: String,
    pub description: String,
    pub icon: String,
}

impl From<OpenWeatherMap> for WeatherForecast {
    fn from(value: OpenWeatherMap) -> Self {
        Self {
            coordinates: Coordinates::default(),
            daily_forecast: value.daily.into_iter()
                .map(DailyWeatherForecast::from)
                .collect(),
            hourly_forecast: value.hourly.into_iter()
                .map(HourlyWeatherForecast::from)
                .collect(),
        }
    }
}

impl From<OWDaily> for DailyWeatherForecast {
    fn from(value: OWDaily) -> Self {
        Self {
            day_temperature: value.temperature.day,
            night_temperature: value.temperature.night,
            morning_temperature: value.temperature.morn,
            evening_temperature: value.temperature.eve,
            max_temperature: value.temperature.max,
            min_temperature: value.temperature.min,
            precipitation_amount: value.rain,
            precipitation_probability: value.precipitation_probability,
            wind_speed: value.wind_speed,
            condition: value.weather.into_iter()
                .next()
                .map(|condition| condition.into())
                .unwrap(),
            day: chrono::Utc.timestamp_opt(value.current_time as i64, 0).unwrap(),
        }
    }
}

impl From<OWHourly> for HourlyWeatherForecast {
    fn from(value: OWHourly) -> Self {
        Self {
            time: chrono::Utc.timestamp_opt(value.current_time as i64, 0).unwrap(),
            temperature: value.temperature,
            precipitation_amount: value.rain,
            precipitation_probability: value.precipitation_probability,
            wind_speed: value.wind_speed,
            condition: value.weather.into_iter()
                .next()
                .map(|condition| condition.into())
                .unwrap(),
        }
    }
}

impl From<OWMWeatherCondition> for WeatherCondition {
    fn from(value: OWMWeatherCondition) -> Self {
        match value.id {
            200..=299 => WeatherCondition::Thunderstorm,
            300..=399 => WeatherCondition::Rain,
            500..=599 => WeatherCondition::Rain,
            600..=699 => WeatherCondition::Snow,
            700..=799 => todo!(),
            800 => WeatherCondition::Sunny,
            801..=899 => WeatherCondition::Clouds,
            _ => unimplemented!(),
        }
    }
}
