use std::fmt;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use transits::*;

pub mod transits;

#[derive(Clone)]
pub struct TripListModel {
    pub id: Uuid,
    pub name: String,
    pub start_date: DateTime<Utc>,
    pub end_date: DateTime<Utc>,
    pub header_image: Option<Vec<u8>>,
}

#[derive(Clone)]
pub struct TripOverviewModel {
    pub id: Uuid,
    pub name: String,
    pub header_image: Option<Vec<u8>>,
    pub pending_packing_list_items: usize,
    pub packed_packing_list_items: usize,
    pub total_packing_list_items: usize,
    pub points_of_interest_count: usize,
    pub accommodation_status: Option<AccommodationStatus>,
    pub locations_list: Vec<TripLocationSummary>,
}

#[derive(Clone)]
pub struct AccommodationStatus {
    pub accommodation_name: String,
    pub status_type: AccommodationStatusType,
    pub datetime: DateTime<Utc>,
}

#[derive(Clone)]
pub enum AccommodationStatusType {
    CheckIn,
    CheckOut,
}

#[derive(Clone)]
pub struct TripLocationSummary {
    pub city: String,
    pub country: String,
}

#[derive(Clone)]
pub struct AttachmentListModel {
    pub id: Uuid,
    pub name: String,
    pub file_name: String,
    pub content_type: String,
}

#[derive(Clone)]
pub struct TripLocationListModel {
    pub id: Uuid,
    pub coordinates: Coordinates,
    pub city: String,
    pub country: String,
    pub forecast: Option<WeatherForecast>,
}

#[derive(Clone, Serialize, Deserialize)]
pub struct Trip {
    pub id: Uuid,
    pub name: String,
    pub start_date: DateTime<Utc>,
    pub end_date: DateTime<Utc>,
    pub locations: Vec<Location>,
    #[serde(default)]
    pub transits: Vec<Transit>,
    #[serde(default)]
    pub accommodations: Vec<AccommodationModel>,
    pub header_image: Option<Vec<u8>>,
    #[serde(default)]
    pub attachments: Vec<TripAttachment>,
}

impl fmt::Debug for Trip {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("Trip")
            .field("id", &self.id)
            .field("name", &self.name)
            .field("start_date", &self.start_date)
            .field("end_date", &self.end_date)
            .field("locations", &self.locations)
            .field("transits", &self.transits)
            .field("accommodations", &self.accommodations)
            .field("header_image", &self.header_image.is_some())
            .field("attachments", &self.attachments.len())
            .finish()
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AccommodationModel {
    pub id: Uuid,
    pub name: String,
    pub address: Option<String>,
    pub check_in: DateTime<Utc>,
    pub check_out: DateTime<Utc>,
    pub attachments: Vec<TripAttachment>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PointOfInterestModel {
    pub id: Uuid,
    pub name: String,
    pub address: String,
    pub website: Option<String>,
    pub opening_hours: Option<String>,
    pub price: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TripAttachment {
    pub id: Uuid,
    pub name: String,
    pub file_name: String,
    pub content_type: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Location {
    pub coordinates: Coordinates,
    pub city: String,
    pub country: String,
    pub forecast: Option<WeatherForecast>,
    pub attachments: Vec<TripAttachment>,
}

#[derive(Default, Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Coordinates {
    pub latitude: f64,
    pub longitude: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeatherForecast {
    pub hourly_forecast: Vec<HourlyWeatherForecast>,
    pub daily_forecast: Vec<DailyWeatherForecast>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HourlyWeatherForecast {
    pub time: DateTime<Utc>,
    pub temperature: f64,
    pub wind_speed: f64,
    /// mm/h
    pub precipitation_amount: f64,
    pub precipitation_probability: f64,
    pub condition: WeatherCondition,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DailyWeatherForecast {
    pub day: DateTime<Utc>,
    pub min_temperature: f64,
    pub max_temperature: f64,
    pub morning_temperature: f64, // 9
    pub day_temperature: f64, // 15
    pub evening_temperature: f64, // 18
    pub night_temperature: f64, // 21
    pub condition: WeatherCondition,
    /// mm
    pub precipitation_amount: f64,
    pub precipitation_probability: f64,
    pub wind_speed: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PackingListEntry {
    pub id: Uuid,
    pub name: String,
    #[serde(default)]
    pub description: Option<String>,
    pub conditions: Vec<PackingListEntryCondition>,
    pub quantity: Quantity,
    #[serde(default)]
    pub category: Option<String>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub struct Quantity {
    pub per_day: Option<usize>,
    pub per_night: Option<usize>,
    pub fixed: Option<usize>,
}

impl Quantity {
    pub(crate) fn calculate(&self, start_date: DateTime<Utc>, end_date: DateTime<Utc>) -> Option<usize> {
        let mut quantity = self.fixed.unwrap_or_default();
        let duration = end_date.signed_duration_since(start_date);
        let days = duration.num_days() as usize;
        let nights = days.saturating_sub(1);
        if let Some(per_day) = self.per_day {
            quantity += per_day * days;
        }
        if let Some(per_night) = self.per_night {
            quantity += per_night * nights;
        }

        if quantity > 0 {
            Some(quantity)
        }else {
            None
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum PackingListEntryCondition {
    MinTripDuration {
        length: u32
    },
    MaxTripDuration {
        length: u32
    },
    MinTemperature {
        temperature: f64,
    },
    MaxTemperature {
        temperature: f64,
    },
    Weather {
        condition: WeatherCondition,
        min_probability: f64,
    },
    Tag {
        tag: String,
    },
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum WeatherCondition {
    Thunderstorm,
    Sunny,
    Rain,
    Clouds,
    Snow,
}

#[derive(Debug, Clone)]
pub struct TripPackingListModel {
    pub groups: Vec<TripPackingListGroup>,
    pub entries: Vec<TripPackingListEntry>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TripPackingListGroup {
    pub id: Uuid,
    pub name: String,
    pub entries: Vec<TripPackingListEntry>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TripPackingListEntry {
    pub packing_list_entry: PackingListEntry,
    pub is_packed: bool,
    pub quantity: Option<usize>,
}

#[derive(Debug, Clone)]
pub struct LocationEntry {
    pub name: String,
    pub coordinates: Coordinates,
    pub country: String,
}

#[derive(Debug, Clone)]
pub struct PackingList {
    pub uncategorized: Vec<PackingListEntry>,
    pub categories: Vec<PackingListCategory>,
}

#[derive(Debug, Clone)]
pub struct PackingListCategory {
    pub name: String,
    pub entries: Vec<PackingListEntry>,
}
