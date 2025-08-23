use std::fmt;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
pub use timeline::*;
pub use transits::*;
pub use web_images::*;
pub use bookings::*;
pub use tidal_information::*;

pub mod web_images;
pub mod transits;
pub mod bookings;
pub mod timeline;
pub mod tidal_information;
pub mod point_of_interests;

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
    pub start_date: DateTime<Utc>,
    pub end_date: DateTime<Utc>,
    pub duration_days: i64,
    pub header_image: Option<Vec<u8>>,
    pub pending_packing_list_items: usize,
    pub total_packing_list_items: usize,
    pub points_of_interest_count: usize,
    pub bookings_count: usize,
    pub next_transit: Option<TransitOverviewModel>,
    pub accommodation_status: Option<AccommodationStatus>,
    pub locations_list: Vec<TripLocationSummary>,
    pub single_location_weather_tidal: Option<TripLocationListModel>,
}

#[derive(Clone)]
pub enum TransitOverviewModel {
    UpcomingTransits(usize),
    DepartingTrain(TrainOverviewModel),
    ArrivingTrain(TrainOverviewModel),
    DepartingFlight(FlightOverviewModel),
    ArrivingFlight(FlightOverviewModel),
}

#[derive(Clone)]
pub struct TrainOverviewModel {
    pub train_number: Option<String>,
    pub time: DateTime<Utc>,
    pub station: String,
    pub platform: String,
}

#[derive(Clone)]
pub struct FlightOverviewModel {
    pub flight_number: String,
    pub airline: String,
    pub time: DateTime<Utc>,
    pub airport: String,
    pub terminal: String,
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
    pub coordinates: Coordinate,
    pub city: String,
    pub country: String,
    pub forecast: Option<WeatherForecast>,
    pub is_coastal: bool,
    pub tidal_information_last_updated: Option<DateTime<Utc>>,
    pub tidal_information: Vec<TidalInformation>,
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
    pub trip_id: Uuid,
    pub name: String,
    pub address: String,
    pub coordinates: Option<Coordinate>,
    pub website: Option<String>,
    pub opening_hours: Option<String>,
    pub price: Option<String>,
    pub phone_number: Option<String>,
    pub note: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TripAttachment {
    pub id: Uuid,
    pub name: String,
    pub file_name: String,
    pub content_type: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TagModel {
    pub id: Uuid,
    pub name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Location {
    pub coordinates: Coordinate,
    pub city: String,
    pub country: String,
    pub forecast: Option<WeatherForecast>,
    pub attachments: Vec<TripAttachment>,
}

#[derive(Default, Debug, Clone, Copy, Serialize, Deserialize, PartialEq)]
pub struct Coordinate {
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
        let duration = duration + chrono::Duration::days(1);
        let days = duration.num_days() as usize;
        let nights = days.saturating_sub(1);
        tracing::debug!(
            "Calculating from {} to {} quantity: fixed: {:?}, per_day: {:?}, per_night: {:?}, days: {}, nights: {}",
            start_date, end_date, self.fixed, self.per_day, self.per_night, days, nights
        );
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
        tag_id: Uuid,
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
    pub coordinates: Coordinate,
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

#[cfg(test)]
mod tests {
    use super::*;
    use test_case::test_case;
    use googletest::prelude::*;
    use chrono::TimeZone;

    fn dt(y: i32, m: u32, d: u32) -> DateTime<Utc> {
        Utc.with_ymd_and_hms(y, m, d, 0, 0, 0).single().expect("valid date")
    }

    #[test_case(2)]
    #[test_case(5)]
    fn calculate_fixed_only_returns_fixed(count: usize) {
        let q = Quantity { per_day: None, per_night: None, fixed: Some(count) };
        let start = dt(2024, 1, 1);
        let end = dt(2024, 1, 1);

        let result = q.calculate(start, end);

        assert_that!(result, eq(Some(count)));
    }

    #[test_case(dt(2024, 1, 1), dt(2024, 1, 1), Some(2); "same day -> 1 day")]
    #[test_case(dt(2024, 1, 1), dt(2024, 1, 2), Some(4); "two consecutive days -> 2 days")]
    #[test_case(dt(2024, 1, 1), dt(2024, 1, 3), Some(6); "three consecutive days -> 3 days")]
    fn calculate_per_day_only(start: DateTime<Utc>, end: DateTime<Utc>, expected: Option<usize>) {
        let q = Quantity { per_day: Some(2), per_night: None, fixed: None };

        let result = q.calculate(start, end);

        assert_that!(result, eq(expected));
    }

    #[test_case(dt(2024, 2, 10), dt(2024, 2, 10), None; "same day -> 0 nights")]
    #[test_case(dt(2024, 2, 10), dt(2024, 2, 11), Some(1); "two days -> 1 night")]
    #[test_case(dt(2024, 2, 10), dt(2024, 2, 12), Some(2); "three days -> 2 nights")]
    fn calculate_per_night_only(start: DateTime<Utc>, end: DateTime<Utc>, expected: Option<usize>) {
        let q = Quantity { per_day: None, per_night: Some(1), fixed: None };

        let result = q.calculate(start, end);

        assert_that!(result, eq(expected));
    }

    #[test]
    fn calculate_combined_components() {
        let q = Quantity { per_day: Some(2), per_night: Some(1), fixed: Some(5) };
        let start = dt(2024, 3, 5);
        let end = dt(2024, 3, 8);

        let result = q.calculate(start, end);

        assert_that!(result, eq(Some(16)));
    }

    #[test]
    fn calculate_returns_none_when_zero() {
        let q = Quantity { per_day: None, per_night: None, fixed: None };
        let start = dt(2024, 3, 5);
        let end = dt(2024, 3, 8);

        let result = q.calculate(start, end);

        assert_that!(result, eq(None));
    }
}
