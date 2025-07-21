use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use super::TripAttachment;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Booking {
    Reservation(Reservation),
    CarRental(CarRental),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Reservation {
    pub id: Uuid,
    pub title: String,
    pub address: Option<String>,
    pub start_date: DateTime<Utc>,
    pub end_date: Option<DateTime<Utc>>,
    pub link: Option<String>,
    pub booking_number: Option<String>,
    #[serde(default)]
    pub attachments: Vec<TripAttachment>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CarRental {
    pub id: Uuid,
    pub provider: String,
    pub pick_up_date: DateTime<Utc>,
    pub pick_up_location: String,
    pub return_date: DateTime<Utc>,
    pub return_location: Option<String>,
    pub booking_number: Option<String>,
    #[serde(default)]
    pub attachments: Vec<TripAttachment>,
}
