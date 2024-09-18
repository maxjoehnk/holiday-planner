use uuid::Uuid;
use crate::models::LocationEntry;

#[derive(Debug)]
pub struct AddTripLocation {
    pub trip_id: Uuid,
    pub location: LocationEntry,
}
