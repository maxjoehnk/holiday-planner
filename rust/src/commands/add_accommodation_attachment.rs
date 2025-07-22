use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct AddAccommodationAttachment {
    pub accommodation_id: Uuid,
    pub name: String,
    pub path: String,
}
