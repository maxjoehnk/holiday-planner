use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct DeleteAttachment {
    pub attachment_id: Uuid,
}
