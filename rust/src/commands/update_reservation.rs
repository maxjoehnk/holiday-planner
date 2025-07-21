use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Debug)]
pub struct UpdateReservation {
    pub id: Uuid,
    pub title: String,
    pub address: Option<String>,
    pub start_date: DateTime<Utc>,
    pub end_date: Option<DateTime<Utc>>,
    pub link: Option<String>,
    pub booking_number: Option<String>,
}
