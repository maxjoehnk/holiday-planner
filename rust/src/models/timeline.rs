use chrono::{DateTime, Utc};
use crate::models::bookings::ReservationCategory;

pub struct TimelineModel {
    pub past: Vec<TimelineItem>,
    pub future: Vec<TimelineItem>,
}

pub struct TimelineItem {
    pub date: DateTime<Utc>,
    pub details: TimelineItemDetails,
}

pub enum TimelineItemDetails {
    CarRentalPickUp {
        provider: String,
        address: String,
    },
    CarRentalDropOff {
        provider: String,
        address: String,
    },
    Reservation {
        title: String,
        address: Option<String>,
        category: ReservationCategory,
    },
    CheckIn {
        address: Option<String>,
    },
    CheckOut {
        address: Option<String>,
    },
    FlightTakeOff {
        airport: String,
        flight_number: String,
        seat: Option<String>,
    },
    FlightLanding {
        airport: String,
        flight_number: String,
    },
    TrainOrigin {
        station: String,
        train_number: String,
        seat: Option<String>,
    },
    TrainDestination {
        station: String,
        train_number: String,
    },
}
