use chrono::{DateTime, Utc};
use uuid::Uuid;
use crate::models::Coordinate;

#[derive(Debug)]
pub struct AddTripAccommodation {
    pub trip_id: Uuid,
    pub name: String,
    pub check_in: Option<DateTime<Utc>>,
    pub check_out: Option<DateTime<Utc>>,
    pub address: Option<String>,
    pub coordinate: Option<Coordinate>,
}
