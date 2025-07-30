use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct UpdateTag {
    pub id: Uuid,
    pub name: String,
}
