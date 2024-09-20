use uuid::Uuid;
use crate::models::{Quantity, PackingListEntryCondition};

#[derive(Debug, Clone)]
pub struct UpdatePackingListEntry {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub conditions: Vec<PackingListEntryCondition>,
    pub quantity: Quantity,
    pub category: Option<String>,
}
