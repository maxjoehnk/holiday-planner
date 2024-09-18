use super::DB;
use crate::commands::*;
use crate::handlers::*;
use crate::models::*;

#[tracing::instrument]
pub fn get_packing_list() -> anyhow::Result<Vec<PackingListEntry>> {
    let handler = DB.try_get::<PackingListHandler>()?;
    handler.get_packing_list()
}

#[tracing::instrument]
pub fn add_packing_list_entry(command: AddPackingListEntry) -> anyhow::Result<PackingListEntry> {
    let handler = DB.try_get::<PackingListHandler>()?;
    handler.add_packing_list_entry(command)
}

#[tracing::instrument]
pub fn delete_packing_list_entry(command: DeletePackingListEntry) -> anyhow::Result<()> {
    let handler = DB.try_get::<PackingListHandler>()?;
    handler.delete_packing_list_entry(command)
}
