use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::models::Coordinate;
use crate::models::bookings::ReservationCategory;

#[derive(Debug, Clone)]
pub struct TripDayView {
    pub id: Option<Uuid>,
    pub trip_id: Uuid,
    pub date: DateTime<Utc>,
    pub day_index: i32,
    pub title: Option<String>,
    pub locations: Vec<DayLocation>,
    pub weather: Option<DayWeather>,
    pub items: Vec<DayItem>,
}

#[derive(Debug, Clone)]
pub struct DayLocation {
    pub location_id: Uuid,
    pub city: String,
    pub country: String,
    pub coordinates: Coordinate,
    pub is_primary: bool,
}

#[derive(Debug, Clone)]
pub struct DayWeather {
    pub location_id: Uuid,
    pub min_temperature: f64,
    pub max_temperature: f64,
    pub condition: crate::models::WeatherCondition,
    pub precipitation_amount: f64,
    pub precipitation_probability: f64,
}

#[derive(Debug, Clone)]
pub struct DayItem {
    pub scheduled_at: Option<DateTime<Utc>>,
    pub details: DayItemDetails,
}

#[derive(Debug, Clone)]
pub enum DayItemDetails {
    PointOfInterest {
        id: Uuid,
        name: String,
        address: String,
        day_order: i32,
    },
    Route {
        id: Uuid,
        name: String,
        sport: Option<String>,
        distance_meters: f64,
        duration_seconds: i64,
        day_order: i32,
    },
    AccommodationCheckIn {
        accommodation_id: Uuid,
        name: String,
        address: Option<String>,
        check_in: DateTime<Utc>,
    },
    AccommodationCheckOut {
        accommodation_id: Uuid,
        name: String,
        address: Option<String>,
        check_out: DateTime<Utc>,
    },
    AccommodationStay {
        accommodation_id: Uuid,
        name: String,
    },
    TrainDeparture {
        train_id: Uuid,
        station: String,
        train_number: Option<String>,
        seat: Option<String>,
        scheduled: DateTime<Utc>,
    },
    TrainArrival {
        train_id: Uuid,
        station: String,
        train_number: Option<String>,
        scheduled: DateTime<Utc>,
    },
    Reservation {
        reservation_id: Uuid,
        title: String,
        address: Option<String>,
        category: ReservationCategory,
        start: DateTime<Utc>,
        end: Option<DateTime<Utc>>,
    },
    CarRentalPickUp {
        car_rental_id: Uuid,
        provider: String,
        address: String,
        pick_up: DateTime<Utc>,
    },
    CarRentalDropOff {
        car_rental_id: Uuid,
        provider: String,
        address: Option<String>,
        drop_off: DateTime<Utc>,
    },
}

#[derive(Debug, Clone)]
pub struct UnassignedItems {
    pub points_of_interest: Vec<UnassignedPoi>,
    pub routes: Vec<UnassignedRoute>,
}

#[derive(Debug, Clone)]
pub struct UnassignedPoi {
    pub id: Uuid,
    pub name: String,
    pub address: String,
}

#[derive(Debug, Clone)]
pub struct UnassignedRoute {
    pub id: Uuid,
    pub name: String,
    pub sport: Option<String>,
    pub distance_meters: f64,
    pub duration_seconds: i64,
}
