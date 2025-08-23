use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct DeleteTrip {
    pub trip_id: Uuid,
}
