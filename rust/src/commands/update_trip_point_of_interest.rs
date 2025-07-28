use uuid::Uuid;

#[derive(Debug)]
pub struct UpdateTripPointOfInterest {
    pub id: Uuid,
    pub name: String,
    pub address: String,
    pub website: Option<String>,
    pub opening_hours: Option<String>,
    pub price: Option<String>,
    pub phone_number: Option<String>,
    pub note: Option<String>,
}
