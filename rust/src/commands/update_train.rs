use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Debug)]
pub struct UpdateTrain {
    pub id: Uuid,
    pub train_number: Option<String>,
    pub departure_station_name: String,
    pub departure_station_city: Option<String>,
    pub departure_station_country: Option<String>,
    pub departure_scheduled_platform: String,
    pub arrival_station_name: String,
    pub arrival_station_city: Option<String>,
    pub arrival_station_country: Option<String>,
    pub arrival_scheduled_platform: String,
    pub scheduled_departure_time: DateTime<Utc>,
    pub scheduled_arrival_time: DateTime<Utc>,
}
