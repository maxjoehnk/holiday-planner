use uuid::Uuid;
use super::DB;
use crate::commands::*;
use crate::handlers::*;
use crate::models::AttachmentListModel;

#[tracing::instrument]
pub async fn get_trip_attachments(trip_id: Uuid) -> anyhow::Result<Vec<AttachmentListModel>> {
    let handler = DB.try_get::<AttachmentHandler>().await?;
    handler.get_trip_attachments(trip_id).await
}

#[tracing::instrument]
pub async fn add_trip_attachment(command: AddTripAttachment) -> anyhow::Result<()> {
    let handler = DB.try_get::<AttachmentHandler>().await?;
    handler.add_trip_attachment(command).await
}

#[tracing::instrument]
pub async fn read_attachment(attachment_id: Uuid, target_path: String) -> anyhow::Result<()> {
    let handler = DB.try_get::<AttachmentHandler>().await?;
    handler.read_attachment(attachment_id, &target_path).await
}

#[tracing::instrument]
pub async fn delete_attachment(attachment_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<AttachmentHandler>().await?;
    handler.delete_attachment(attachment_id).await
}
