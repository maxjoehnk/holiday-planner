use crate::models::{Quantity, PackingListEntryCondition};

#[derive(Debug, Clone)]
pub struct AddPackingListEntry {
    pub name: String,
    pub conditions: Vec<PackingListEntryCondition>,
    pub quantity: Quantity,
}
