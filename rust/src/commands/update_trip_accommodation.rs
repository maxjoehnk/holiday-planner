use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Debug, Clone)]
pub struct UpdateTripAccommodation {
    pub id: Uuid,
    pub name: String,
    pub address: Option<String>,
    pub check_in: DateTime<Utc>,
    pub check_out: DateTime<Utc>,
}
