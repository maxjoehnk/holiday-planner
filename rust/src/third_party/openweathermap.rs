use std::cmp::Ordering;
use chrono::{Datelike, Timelike, TimeZone};
use serde::Deserialize;
use itertools::Itertools;

use crate::models::{Coordinate, DailyWeatherForecast, HourlyWeatherForecast, WeatherCondition, WeatherForecast};

const API_KEY: Option<&str> = option_env!("OPENWEATHERMAP_API_KEY");

pub async fn get_forecast(coordinates: &Coordinate) -> anyhow::Result<OpenWeatherMap> {
    let Some(key) = API_KEY else {
        anyhow::bail!("OPENWEATHERMAP_API_KEY is not set");
    };
    let url = format!("https://api.openweathermap.org/data/2.5/forecast?lat={}&lon={}&appid={}&units=metric", coordinates.latitude, coordinates.longitude, key);
    let res = reqwest::get(&url).await?;
    let body: OpenWeatherMap = res.json().await?;

    Ok(body)
}

#[derive(Debug, Clone, Deserialize)]
pub struct OpenWeatherMap {
    list: Vec<OWWeather>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct OpenWeatherMapOneCall {
    daily: Vec<OWDaily>,
    hourly: Vec<OWHourly>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct OWWeather {
    #[serde(rename = "dt")]
    pub current_time: u64,
    pub main: OWWeatherMain,
    pub weather: Vec<OWMWeatherCondition>,
    pub wind: OWWind,
}

#[derive(Debug, Clone, Deserialize)]
pub struct OWWeatherMain {
    #[serde(rename = "temp")]
    pub temperature: f64,
    #[serde(rename = "feels_like")]
    pub feels_like: f64,
    #[serde(rename = "temp_min")]
    pub min_temperature: f64,
    #[serde(rename = "temp_max")]
    pub max_temperature: f64,
    pub pressure: u32,
    pub humidity: u32,
}

#[derive(Debug, Clone, Deserialize)]
pub struct OWWind {
    pub speed: f64,
    pub deg: u32,
    pub gust: f64,
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
            daily_forecast: value.list.iter()
                .chunk_by(get_date)
                .into_iter()
                .flat_map(|(_, forecasts)| {
                    let forecasts = forecasts.collect::<Vec<_>>();

                    approximate_daily_forecast(forecasts)
                })
                .collect(),
            hourly_forecast: value.list.into_iter()
                .map(HourlyWeatherForecast::from)
                .collect(),
        }
    }
}

fn approximate_daily_forecast(forecasts: Vec<&OWWeather>) -> Option<DailyWeatherForecast> {
    if forecasts.is_empty() {
        return None;
    }
    assert!(!forecasts.is_empty());
    let max_temperature = forecasts.iter().map(|f| f.main.max_temperature).max_by(|lhs, rhs| if lhs - rhs > 0. {
        Ordering::Greater
    }else {
        Ordering::Less
    })?;
    let min_temperature = forecasts.iter().map(|f| f.main.max_temperature).min_by(|lhs, rhs| if lhs - rhs > 0. {
        Ordering::Greater
    }else {
        Ordering::Less
    })?;
    let day = chrono::Utc.timestamp_opt(forecasts.first()?.current_time as i64, 0).unwrap();
    fn is_hour(target: u32) -> impl FnMut(&&&OWWeather) -> bool {
        return move |weather| get_hour(weather) == target
    }
    let morning_temperature = forecasts.iter().find(is_hour(9)).map(get_temperature)?;
    let day_temperature = forecasts.iter().find(is_hour(15)).map(get_temperature)?;
    let evening_temperature = forecasts.iter().find(is_hour(18)).map(get_temperature)?;
    let night_temperature = forecasts.iter().find(is_hour(21)).map(get_temperature)?;

    let day_weather = forecasts.iter().find(is_hour(15)).or_else(|| forecasts.first())?;

    let condition = forecasts.iter()
        .filter(|forecast| get_hour(forecast) >= 6)
        .flat_map(|forecasts| forecasts.weather.iter().cloned().map(WeatherCondition::from))
        .counts()
        .into_iter()
        .max_by_key(|(_, count)| *count)
        .map(|(condition, _)| condition)?;

    Some(DailyWeatherForecast {
        day,
        max_temperature,
        min_temperature,
        morning_temperature,
        day_temperature,
        evening_temperature,
        night_temperature,
        condition,
        wind_speed: day_weather.wind.speed,
        precipitation_amount: 0.,
        precipitation_probability: 0.
    })
}

fn get_hour(weather: &OWWeather) -> u32 {
    let time = weather.current_time;
    chrono::Utc.timestamp_opt(time as i64, 0).unwrap().hour()
}

fn get_date(weather: &&OWWeather) -> (u32, u32, i32) {
    let time = weather.current_time;
    let weather = chrono::Utc.timestamp_opt(time as i64, 0).unwrap();

    (weather.day(), weather.month(), weather.year())
}

fn get_temperature(weather: &&OWWeather) -> f64 {
    weather.main.temperature
}

impl From<OWWeather> for HourlyWeatherForecast {
    fn from(value: OWWeather) -> Self {
        Self {
            time: chrono::Utc.timestamp_opt(value.current_time as i64, 0).unwrap(),
            temperature: value.main.temperature,
            precipitation_amount: 0.0,
            precipitation_probability: 0.0,
            wind_speed: value.wind.speed,
            condition: value.weather.into_iter()
                .next()
                .map(|condition| condition.into())
                .unwrap(),
        }
    }
}

impl From<OpenWeatherMapOneCall> for WeatherForecast {
    fn from(value: OpenWeatherMapOneCall) -> Self {
        Self {
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
