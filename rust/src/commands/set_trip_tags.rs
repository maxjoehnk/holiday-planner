use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct SetTripTags {
    pub trip_id: Uuid,
    pub tag_ids: Vec<Uuid>,
}
