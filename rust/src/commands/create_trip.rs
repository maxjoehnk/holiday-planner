use chrono::Utc;

#[derive(Debug, Clone)]
pub struct CreateTrip {
    pub name: String,
    pub start_date: chrono::DateTime<Utc>,
    pub end_date: chrono::DateTime<Utc>,
    pub header_image: Option<Vec<u8>>,
}
