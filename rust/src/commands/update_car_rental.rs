use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Debug)]
pub struct UpdateCarRental {
    pub id: Uuid,
    pub provider: String,
    pub pick_up_date: DateTime<Utc>,
    pub pick_up_location: String,
    pub return_date: DateTime<Utc>,
    pub return_location: Option<String>,
    pub booking_number: Option<String>,
}
