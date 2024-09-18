use std::path::Path;
use uuid::Uuid;
use crate::commands::AddTripAttachment;
use crate::database::Database;
use crate::handlers::Handler;
use crate::models::{Attachment, TripAttachment};

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
    pub fn add_trip_attachment(&self, command: AddTripAttachment) -> anyhow::Result<()> {
        tracing::debug!("Adding attachment to trip {}", command.trip_id);
        let path = Path::new(&command.path);
        let file_name = path.file_name().unwrap().to_str().unwrap().to_string();
        let data = std::fs::read(&command.path)?;
        let content_type = infer::get(&data)
            .map(|file_type| file_type.mime_type()).unwrap_or("application/octet-stream");
        let attachment = Attachment {
            id: Uuid::new_v4(),
            name: command.name,
            file_name,
            data,
            content_type: content_type.to_string(),
        };
        let trip_attachment = TripAttachment {
            id: attachment.id,
            name: attachment.name.clone(),
            file_name: attachment.file_name.clone(),
            content_type: attachment.content_type.clone(),
        };
        self.db.trip_tree().update_and_fetch(&command.trip_id, |trip| {
            let mut trip = trip?;
            trip.attachments.push(trip_attachment.clone());

            Some(trip)
        })?.ok_or_else(|| anyhow::anyhow!("Trip not found"))?;
        self.db.attachments_tree().insert(&attachment.id, &attachment)?;

        Ok(())
    }

    pub fn delete_attachment(&self, attachment_id: Uuid) -> anyhow::Result<()> {
        self.db.attachments_tree().remove(&attachment_id)?.ok_or_else(|| anyhow::anyhow!("Attachment not found"))?;
        for trip in self.db.trip_tree().iter() {
            if let Ok((trip_id, mut trip)) = trip {
                trip.attachments.retain(|attachment| attachment.id != attachment_id);
                self.db.trip_tree().insert(&trip_id, &trip)?;
            }
        }

        Ok(())
    }

    pub fn read_attachment(&self, attachment_id: Uuid, target_path: &impl AsRef<Path>) -> anyhow::Result<()> {
        let attachment = self.db.attachments_tree().get(&attachment_id)?.ok_or_else(|| anyhow::anyhow!("Attachment not found"))?;

        std::fs::write(target_path, &attachment.data)?;

        Ok(())
    }
}
