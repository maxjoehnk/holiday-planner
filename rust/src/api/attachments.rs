use uuid::Uuid;
use super::DB;
use crate::commands::*;
use crate::handlers::*;

#[tracing::instrument]
pub fn add_trip_attachment(command: AddTripAttachment) -> anyhow::Result<()> {
    let handler = DB.try_get::<AttachmentHandler>()?;
    handler.add_trip_attachment(command)
}

#[tracing::instrument]
pub fn read_attachment(attachment_id: Uuid, target_path: String) -> anyhow::Result<()> {
    let handler = DB.try_get::<AttachmentHandler>()?;
    handler.read_attachment(attachment_id, &target_path)
}

#[tracing::instrument]
pub fn delete_attachment(attachment_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<AttachmentHandler>()?;
    handler.delete_attachment(attachment_id)
}
