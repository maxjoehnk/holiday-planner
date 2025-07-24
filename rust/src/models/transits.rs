use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Transit {
    Flight(Flight),
    Train(Train),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Flight {
    pub flight_number: String,
    pub departure: Airport,
    pub arrival: Airport,
    pub scheduled_departure_time: DateTime<Utc>,
    pub scheduled_arrival_time: DateTime<Utc>,
    pub estimated_departure_time: Option<DateTime<Utc>>,
    pub estimated_arrival_time: Option<DateTime<Utc>>,
    pub airline: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Airport {
    pub name: String,
    pub iata: String,
    pub icao: String,
    pub city: String,
    pub country: String,
    pub terminal: String,
    pub gate: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Train {
    pub id: Uuid,
    pub train_number: Option<String>,
    pub departure: TrainStation,
    pub arrival: TrainStation,
    pub scheduled_departure_time: DateTime<Utc>,
    pub scheduled_arrival_time: DateTime<Utc>,
    pub estimated_departure_time: Option<DateTime<Utc>>,
    pub estimated_arrival_time: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TrainStation {
    pub name: String,
    pub scheduled_platform: String,
    pub actual_platform: Option<String>,
    pub city: Option<String>,
    pub country: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParsedTrainSegment {
    pub train_number: Option<String>,
    pub departure_station_name: String,
    pub departure_station_city: Option<String>,
    pub departure_station_country: Option<String>,
    pub departure_scheduled_platform: Option<String>,
    pub arrival_station_name: String,
    pub arrival_station_city: Option<String>,
    pub arrival_station_country: Option<String>,
    pub arrival_scheduled_platform: Option<String>,
    pub scheduled_departure_time: DateTime<Utc>,
    pub scheduled_arrival_time: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParsedTrainJourney {
    pub segments: Vec<ParsedTrainSegment>,
    pub journey_url: Option<String>,
}
