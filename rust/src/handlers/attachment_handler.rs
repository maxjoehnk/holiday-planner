use std::path::Path;
use sea_orm::ActiveValue::Set;
use uuid::Uuid;
use crate::commands::AddTripAttachment;
use crate::database::{Database, entities, repositories};
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
        tracing::debug!("Adding attachment to trip {}", command.trip_id);
        let path = Path::new(&command.path);
        let file_name = path.file_name().unwrap().to_str().unwrap().to_string();
        let data = std::fs::read(&command.path)?;
        let content_type = infer::get(&data)
            .map(|file_type| file_type.mime_type())
            .unwrap_or("application/octet-stream")
            .to_string();
        
        let attachment = entities::attachment::ActiveModel {
            id: Set(Uuid::new_v4()),
            trip_id: Set(command.trip_id),
            name: Set(command.name),
            file_name: Set(file_name),
            data: Set(data),
            content_type: Set(content_type),
        };
        
        repositories::attachments::insert(&self.db, attachment).await?;

        Ok(())
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
        repositories::attachments::delete_by_id(&self.db, attachment_id).await?;

        Ok(())
    }

    pub async fn read_attachment(&self, attachment_id: Uuid, target_path: &impl AsRef<Path>) -> anyhow::Result<()> {
        let attachment = repositories::attachments::find_by_id(&self.db, attachment_id).await?
            .ok_or_else(|| anyhow::anyhow!("Attachment not found"))?;

        std::fs::write(target_path, &attachment.data)?;

        Ok(())
    }
}
