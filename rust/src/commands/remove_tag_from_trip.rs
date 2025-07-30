use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct RemoveTagFromTrip {
    pub trip_id: Uuid,
    pub tag_id: Uuid,
}
