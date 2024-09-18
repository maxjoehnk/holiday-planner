use chrono::NaiveDate;
use serde::Deserialize;

const API_KEY: &str = env!("AVIATIONSTACK_API_KEY");

pub fn get_flight(flight_number: &str, date: NaiveDate) -> anyhow::Result<Vec<AviationstackFlightStatus>> {
    let url = format!("https://api.aviationstack.com/v1/flights?access_key={}&flight_iata={}&flight_date={}", API_KEY, flight_number, date.format("%Y-%m-%d"));
    let res = reqwest::blocking::get(&url)?;
    let body: AviationstackResponse<AviationstackFlightStatus> = res.json()?;

    Ok(body.data)
}

#[derive(Debug, Clone, Deserialize)]
struct AviationstackResponse<T> {
    data: Vec<T>,
    pagination: AviationstackPagination,
}

#[derive(Debug, Clone, Deserialize)]
struct AviationstackPagination {
    limit: u64,
    offset: u64,
    count: u64,
    total: u64,
}

#[derive(Debug, Clone, Deserialize)]
pub struct AviationstackFlightStatus {
    pub flight_date: String,
    pub flight_status: FlightStatus,
    pub departure: AviationstackAirport,
    pub arrival: AviationstackAirport,
}

#[derive(Debug, Clone, Deserialize)]
pub struct AviationstackAirport {
    pub airport: String,
    pub timezone: String,
    pub iata: String,
    pub icao: String,
    pub terminal: Option<String>,
    pub gate: Option<String>,
    pub delay: u32,
    pub scheduled: String,
    pub estimated: Option<String>,
    pub actual: Option<String>,
    pub estimated_runway: Option<String>,
    pub actual_runway: Option<String>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct AviationstackAirline {
    pub name: String,
    pub iata: String,
    pub icao: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct AviationstackFlight {
    pub number: String,
    pub iata: String,
    pub icao: String,
}

#[derive(Debug, Clone, Copy, Deserialize)]
pub enum FlightStatus {
    Scheduled,
    Active,
    Landed,
    Cancelled,
    Incident,
    Diverted,
}

