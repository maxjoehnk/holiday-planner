use chrono::Utc;
use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct UpdateTrip {
    pub id: Uuid,
    pub name: String,
    pub start_date: chrono::DateTime<Utc>,
    pub end_date: chrono::DateTime<Utc>,
    pub header_image: Option<Vec<u8>>,
}
