use std::ops::Deref;
use std::path::Path;
use futures::TryFutureExt;
use sea_orm::ActiveValue::Set;
use sea_orm::{ConnectionTrait, DbErr, TransactionTrait};
use sha2::{Digest, Sha256};
use uuid::Uuid;
use crate::commands::{AddTripAttachment, AddAccommodationAttachment};
use crate::database::entities::pending_mutation::MutationOperation;
use crate::database::{Database, entities, repositories, DbResult};
use crate::handlers::Handler;
use crate::models::AttachmentListModel;
use crate::sync;

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
        let trip_id = command.trip_id;
        let attachment_id = Self::add_attachment(self.db.deref(), command, data).await?;
        Self::enqueue_attachment(&self.db, trip_id, attachment_id).await?;

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
        let sha = sha256_hex(&data);
        let storage_path = sync::wire::attachment_storage_path(command.trip_id, attachment_id);
        let attachment = entities::attachment::ActiveModel {
            id: Set(attachment_id),
            trip_id: Set(command.trip_id),
            name: Set(command.name),
            file_name: Set(file_name),
            data: Set(data),
            content_type: Set(content_type),
            updated_at: Set(chrono::Utc::now()),
            storage_path: Set(Some(storage_path)),
            sha256: Set(Some(sha)),
            uploaded_at: Set(None),
            ..Default::default()
        };

        repositories::attachments::insert(db, attachment).await?;

        Ok(attachment_id)
    }

    /// Queue a sync push for the just-inserted attachment, if a user is signed in.
    /// Runs outside the local insert transaction so an enqueue failure
    /// never blocks the offline-first write.
    async fn enqueue_attachment(
        db: &Database,
        trip_id: Uuid,
        attachment_id: Uuid,
    ) -> anyhow::Result<()> {
        let Some(_user_id) = sync::session::current_user().await else {
            return Ok(());
        };
        let Some(model) = repositories::attachments::find_by_id(db, attachment_id).await? else {
            return Ok(());
        };
        let _ = trip_id; // captured so the storage path was correct above.
        let Some(row) = sync::wire::AttachmentRow::from_model(&model) else {
            // No storage_path/sha — shouldn't happen since add_attachment sets both.
            tracing::warn!("attachment {attachment_id} missing storage metadata; skipping enqueue");
            return Ok(());
        };
        sync::push::enqueue(
            db.deref(),
            "attachments",
            attachment_id,
            MutationOperation::Insert,
            &row,
        )
        .await?;
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
        Self::enqueue_attachment_delete(&self.db, attachment_id).await?;
        repositories::attachments::delete_by_id(self.db.deref(), attachment_id).await?;

        Ok(())
    }

    /// Snapshot the storage_path before the local hard-delete so the push
    /// worker can clean up the bucket too.
    async fn enqueue_attachment_delete(db: &Database, attachment_id: Uuid) -> anyhow::Result<()> {
        if sync::session::current_user().await.is_none() {
            return Ok(());
        }
        let Some(existing) = repositories::attachments::find_by_id(db, attachment_id).await? else {
            return Ok(());
        };
        let payload = serde_json::json!({
            "id": attachment_id,
            "storage_path": existing.storage_path,
        });
        sync::push::enqueue(
            db.deref(),
            "attachments",
            attachment_id,
            MutationOperation::Delete,
            &payload,
        )
        .await?;
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
        let accommodation_id = command.accommodation_id;
        let attachment_id = self
            .db
            .transaction::<_, Uuid, DbErr>(move |transaction| {
                Box::pin(async move {
                    let attachment_id = Self::add_attachment(transaction, add_trip_attachment, data).await?;
                    repositories::attachments::add_to_accommodation(transaction, accommodation_id, attachment_id).await?;
                    Ok(attachment_id)
                })
            })
            .await?;
        Self::enqueue_attachment(&self.db, trip_id, attachment_id).await?;
        Self::enqueue_accommodation_attachment(
            &self.db,
            accommodation_id,
            attachment_id,
            MutationOperation::Insert,
        )
        .await?;

        Ok(())
    }

    async fn enqueue_accommodation_attachment(
        db: &Database,
        accommodation_id: Uuid,
        attachment_id: Uuid,
        op: MutationOperation,
    ) -> anyhow::Result<()> {
        if sync::session::current_user().await.is_none() {
            return Ok(());
        }
        let payload = match op {
            MutationOperation::Delete => serde_json::json!({
                "accommodation_id": accommodation_id,
                "attachment_id": attachment_id,
            }),
            _ => serde_json::to_value(sync::wire::AccommodationAttachmentRow {
                accommodation_id,
                attachment_id,
                updated_at: chrono::Utc::now(),
                deleted_at: None,
            })?,
        };
        sync::push::enqueue_if_signed_in(
            db,
            "accommodation_attachments",
            attachment_id,
            op,
            &payload,
        )
        .await
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
        Self::enqueue_accommodation_attachment(
            &self.db,
            accommodation_id,
            attachment_id,
            MutationOperation::Delete,
        )
        .await?;
        Self::enqueue_attachment_delete(&self.db, attachment_id).await?;
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

fn sha256_hex(data: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(data);
    format!("{:x}", hasher.finalize())
}
