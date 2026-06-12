use uuid::Uuid;
use super::DB;
use super::events::{self, DataChangeEvent};
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
    let trip_id = command.trip_id;
    handler.add_trip_attachment(command).await?;
    events::emit(DataChangeEvent::AttachmentsChanged { trip_id: Some(trip_id), accommodation_id: None });
    Ok(())
}

#[tracing::instrument]
pub async fn read_attachment(attachment_id: Uuid, target_path: String) -> anyhow::Result<()> {
    let handler = DB.try_get::<AttachmentHandler>().await?;
    handler.read_attachment(attachment_id, &target_path).await
}

#[tracing::instrument]
pub async fn delete_attachment(attachment_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<AttachmentHandler>().await?;
    handler.delete_attachment(attachment_id).await?;
    events::emit(DataChangeEvent::AttachmentsChanged { trip_id: None, accommodation_id: None });
    Ok(())
}

#[tracing::instrument]
pub async fn get_accommodation_attachments(accommodation_id: Uuid) -> anyhow::Result<Vec<AttachmentListModel>> {
    let handler = DB.try_get::<AttachmentHandler>().await?;
    handler.get_accommodation_attachments(accommodation_id).await
}

#[tracing::instrument]
pub async fn add_accommodation_attachment(command: AddAccommodationAttachment) -> anyhow::Result<()> {
    let handler = DB.try_get::<AttachmentHandler>().await?;
    let accommodation_id = command.accommodation_id;
    handler.add_accommodation_attachment(command).await?;
    events::emit(DataChangeEvent::AttachmentsChanged { trip_id: None, accommodation_id: Some(accommodation_id) });
    Ok(())
}

#[tracing::instrument]
pub async fn remove_accommodation_attachment(accommodation_id: Uuid, attachment_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<AttachmentHandler>().await?;
    handler.remove_accommodation_attachment(accommodation_id, attachment_id).await?;
    events::emit(DataChangeEvent::AttachmentsChanged { trip_id: None, accommodation_id: Some(accommodation_id) });
    Ok(())
}
