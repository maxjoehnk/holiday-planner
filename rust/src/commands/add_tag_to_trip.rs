use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct AddTagToTrip {
    pub trip_id: Uuid,
    pub tag_id: Uuid,
}
