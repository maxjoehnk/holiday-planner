use uuid::Uuid;

#[derive(Debug)]
pub struct UpdateRoute {
    pub id: Uuid,
    pub note: Option<String>,
}
