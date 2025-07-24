use uuid::Uuid;

#[derive(Debug)]
pub struct ParseSharedTrainData {
    pub trip_id: Uuid,
    pub shared_text: String,
}
