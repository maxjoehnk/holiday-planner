use std::ops::Deref;
use std::path::Path;
use futures::TryFutureExt;
use sea_orm::ActiveValue::Set;
use sea_orm::{ConnectionTrait, DbErr, TransactionTrait};
use uuid::Uuid;
use crate::commands::{AddTripAttachment, AddAccommodationAttachment};
use crate::database::{Database, entities, repositories, DbResult};
use crate::handlers::Handler;
use crate::models::AttachmentListModel;

pub struct AttachmentHandler {
    db: Database,
}

impl Handler for AttachmentHandler {
    fn create(db: Database) -> Self {
        Self {
            db,
        }
    }
}

impl AttachmentHandler {
    pub async fn add_trip_attachment(&self, command: AddTripAttachment) -> anyhow::Result<()> {
        let data = std::fs::read(&command.path)?;
        Self::add_attachment(self.db.deref(), command, data).await?;

        Ok(())
    }

    async fn add_attachment(db: &impl ConnectionTrait, command: AddTripAttachment, data: Vec<u8>) -> DbResult<Uuid> {
        tracing::debug!("Adding attachment to trip {}", command.trip_id);
        let path = Path::new(&command.path);
        let file_name = path.file_name().unwrap().to_str().unwrap().to_string();
        let content_type = infer::get(&data)
            .map(|file_type| file_type.mime_type())
            .unwrap_or("application/octet-stream")
            .to_string();

        let attachment_id = Uuid::new_v4();
        let attachment = entities::attachment::ActiveModel {
            id: Set(attachment_id),
            trip_id: Set(command.trip_id),
            name: Set(command.name),
            file_name: Set(file_name),
            data: Set(data),
            content_type: Set(content_type),
        };

        repositories::attachments::insert(db, attachment).await?;

        Ok(attachment_id)
    }

    pub async fn get_trip_attachments(&self, trip_id: Uuid) -> anyhow::Result<Vec<AttachmentListModel>> {
        let attachments = repositories::attachments::find_all_by_trip(&self.db, trip_id).await?;
        let attachments = attachments.into_iter().map(|attachment| AttachmentListModel {
            id: attachment.id,
            name: attachment.name,
            file_name: attachment.file_name,
            content_type: attachment.content_type,
        }).collect();
        
        Ok(attachments)
    }

    pub async fn delete_attachment(&self, attachment_id: Uuid) -> anyhow::Result<()> {
        repositories::attachments::delete_by_id(self.db.deref(), attachment_id).await?;

        Ok(())
    }

    pub async fn read_attachment(&self, attachment_id: Uuid, target_path: &impl AsRef<Path>) -> anyhow::Result<()> {
        let attachment = repositories::attachments::find_by_id(&self.db, attachment_id).await?
            .ok_or_else(|| anyhow::anyhow!("Attachment not found"))?;

        std::fs::write(target_path, &attachment.data)?;

        Ok(())
    }

    pub async fn add_accommodation_attachment(&self, command: AddAccommodationAttachment) -> anyhow::Result<()> {
        tracing::debug!("Adding attachment to accommodation {}", command.accommodation_id);
        let trip_id = repositories::accommodations::find_by_id(&self.db, command.accommodation_id).await?.ok_or_else(|| anyhow::anyhow!("Accommodation not found"))?.trip_id;
        let add_trip_attachment = AddTripAttachment {
            trip_id,
            path: command.path,
            name: command.name,
        };
        let data = std::fs::read(&add_trip_attachment.path)?;
        self.db.transaction::<_, _, DbErr>(move |transaction| {
            Box::pin(async move {
                let attachment_id = Self::add_attachment(transaction, add_trip_attachment, data).await?;
                repositories::attachments::add_to_accommodation(transaction, command.accommodation_id, attachment_id).await?;

                Ok(())
            })
        }).await?;

        Ok(())
    }
    
    pub async fn get_accommodation_attachments(&self, accommodation_id: Uuid) -> anyhow::Result<Vec<AttachmentListModel>> {
        let attachments = repositories::attachments::find_all_by_accommodation(self.db.deref(), accommodation_id).await?;
        let attachments = attachments.into_iter().map(|attachment| AttachmentListModel {
            id: attachment.id,
            name: attachment.name,
            file_name: attachment.file_name,
            content_type: attachment.content_type,
        }).collect();
        
        Ok(attachments)
    }
    
    pub async fn remove_accommodation_attachment(&self, accommodation_id: Uuid, attachment_id: Uuid) -> anyhow::Result<()> {
        self.db.transaction::<_, _, DbErr>(|transaction| {
            Box::pin(async move {
                repositories::attachments::remove_from_accommodation(transaction, accommodation_id, attachment_id).await?;
                repositories::attachments::delete_by_id(transaction, attachment_id).await?;

                Ok(())
            })
        }).await?;

        Ok(())
    }
}
