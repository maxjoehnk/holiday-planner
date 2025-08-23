use crate::models::Coordinate;

pub struct PointOfInterestSearchModel {
    pub id: u64,
    pub name: String,
    pub address: Option<String>,
    pub country: String,
    pub coordinate: Option<Coordinate>,
}

pub struct PointOfInterestOsmModel {
    pub id: u64,
    pub opening_hours: Option<String>,
    pub website: Option<String>,
    pub phone_number: Option<String>,
}
