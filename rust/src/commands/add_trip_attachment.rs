use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct AddTripAttachment {
    pub trip_id: Uuid,
    pub name: String,
    pub path: String,
}
