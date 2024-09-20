use super::DB;
use crate::commands::*;
use crate::handlers::*;
use crate::models::*;

#[tracing::instrument]
pub async fn get_packing_list() -> anyhow::Result<Vec<PackingListEntry>> {
    let handler = DB.try_get::<PackingListHandler>().await?;
    handler.get_packing_list().await
}

#[tracing::instrument]
pub async fn add_packing_list_entry(command: AddPackingListEntry) -> anyhow::Result<()> {
    let handler = DB.try_get::<PackingListHandler>().await?;
    handler.add_packing_list_entry(command).await
}

#[tracing::instrument]
pub async fn update_packing_list_entry(command: UpdatePackingListEntry) -> anyhow::Result<()> {
    let handler = DB.try_get::<PackingListHandler>().await?;
    handler.update_packing_list_entry(command).await
}

#[tracing::instrument]
pub async fn delete_packing_list_entry(command: DeletePackingListEntry) -> anyhow::Result<()> {
    let handler = DB.try_get::<PackingListHandler>().await?;
    handler.delete_packing_list_entry(command).await
}
