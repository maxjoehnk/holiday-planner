use uuid::Uuid;
use super::DB;
use crate::commands::*;
use crate::handlers::*;
use crate::models::*;

#[tracing::instrument]
pub async fn get_all_tags() -> anyhow::Result<Vec<TagModel>> {
    let handler = DB.try_get::<TagHandler>().await?;
    handler.get_all_tags().await
}

#[tracing::instrument]
pub async fn get_tag_by_id(id: Uuid) -> anyhow::Result<Option<TagModel>> {
    let handler = DB.try_get::<TagHandler>().await?;
    handler.get_tag_by_id(id).await
}

#[tracing::instrument]
pub async fn create_tag(command: CreateTag) -> anyhow::Result<TagModel> {
    let handler = DB.try_get::<TagHandler>().await?;
    handler.create_tag(command).await
}

#[tracing::instrument]
pub async fn update_tag(command: UpdateTag) -> anyhow::Result<TagModel> {
    let handler = DB.try_get::<TagHandler>().await?;
    handler.update_tag(command).await
}

#[tracing::instrument]
pub async fn delete_tag(id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<TagHandler>().await?;
    handler.delete_tag(id).await
}

#[tracing::instrument]
pub async fn get_trip_tags(trip_id: Uuid) -> anyhow::Result<Vec<TagModel>> {
    let handler = DB.try_get::<TagHandler>().await?;
    handler.get_trip_tags(trip_id).await
}

#[tracing::instrument]
pub async fn add_tag_to_trip(command: AddTagToTrip) -> anyhow::Result<()> {
    let handler = DB.try_get::<TagHandler>().await?;
    handler.add_tag_to_trip(command).await
}

#[tracing::instrument]
pub async fn remove_tag_from_trip(command: RemoveTagFromTrip) -> anyhow::Result<()> {
    let handler = DB.try_get::<TagHandler>().await?;
    handler.remove_tag_from_trip(command).await
}

#[tracing::instrument]
pub async fn set_trip_tags(command: SetTripTags) -> anyhow::Result<()> {
    let handler = DB.try_get::<TagHandler>().await?;
    handler.set_trip_tags(command).await
}
