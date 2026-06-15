use uuid::Uuid;
use chrono::{DateTime, Utc};
use crate::models::Coordinate;

#[derive(Debug, Clone)]
pub struct UpdateTripAccommodation {
    pub id: Uuid,
    pub name: String,
    pub address: Option<String>,
    pub coordinate: Option<Coordinate>,
    pub check_in: DateTime<Utc>,
    pub check_out: DateTime<Utc>,
}
