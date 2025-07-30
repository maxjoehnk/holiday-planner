use std::ops::Deref;
use uuid::Uuid;
use crate::database::{Database, repositories};
use crate::models::*;
use crate::commands::*;
use crate::handlers::Handler;

pub struct TagHandler {
    db: Database,
}

impl Handler for TagHandler {
    fn create(db: Database) -> Self {
        Self { db }
    }
}

impl TagHandler {
    pub async fn get_all_tags(&self) -> anyhow::Result<Vec<TagModel>> {
        let tags = repositories::tags::find_all(&self.db).await?;
        let tag_models = tags.into_iter()
            .map(|tag| TagModel {
                id: tag.id,
                name: tag.name,
            })
            .collect();

        Ok(tag_models)
    }

    pub async fn get_tag_by_id(&self, id: Uuid) -> anyhow::Result<Option<TagModel>> {
        let tag = repositories::tags::find_by_id(&self.db, id).await?;
        let tag_model = tag.map(|t| TagModel {
            id: t.id,
            name: t.name,
        });

        Ok(tag_model)
    }

    pub async fn create_tag(&self, command: CreateTag) -> anyhow::Result<TagModel> {
        // Check if tag with this name already exists
        let existing_tag = repositories::tags::find_by_name(&self.db, &command.name).await?;
        if existing_tag.is_some() {
            return Err(anyhow::anyhow!("Tag with name '{}' already exists", command.name));
        }

        let tag = repositories::tags::create(&self.db, command.name).await?;
        let tag_model = TagModel {
            id: tag.id,
            name: tag.name,
        };

        Ok(tag_model)
    }

    pub async fn update_tag(&self, command: UpdateTag) -> anyhow::Result<TagModel> {
        // Check if tag exists
        let existing_tag = repositories::tags::find_by_id(&self.db, command.id).await?;
        if existing_tag.is_none() {
            return Err(anyhow::anyhow!("Tag not found"));
        }

        // Check if another tag with this name already exists
        let name_conflict = repositories::tags::find_by_name(&self.db, &command.name).await?;
        if let Some(conflict_tag) = name_conflict {
            if conflict_tag.id != command.id {
                return Err(anyhow::anyhow!("Tag with name '{}' already exists", command.name));
            }
        }

        repositories::tags::update(&self.db, command.id, command.name.clone()).await?;
        
        let tag_model = TagModel {
            id: command.id,
            name: command.name,
        };

        Ok(tag_model)
    }

    pub async fn delete_tag(&self, id: Uuid) -> anyhow::Result<()> {
        // Check if tag exists
        let existing_tag = repositories::tags::find_by_id(&self.db, id).await?;
        if existing_tag.is_none() {
            return Err(anyhow::anyhow!("Tag not found"));
        }

        repositories::tags::delete(&self.db, id).await?;
        Ok(())
    }

    pub async fn get_trip_tags(&self, trip_id: Uuid) -> anyhow::Result<Vec<TagModel>> {
        let tags = repositories::tags::find_by_trip_id(&self.db, trip_id).await?;
        let tag_models = tags.into_iter()
            .map(|tag| TagModel {
                id: tag.id,
                name: tag.name,
            })
            .collect();

        Ok(tag_models)
    }

    pub async fn add_tag_to_trip(&self, command: AddTagToTrip) -> anyhow::Result<()> {
        // Check if trip exists
        let trip = repositories::trips::find_by_id(&self.db, command.trip_id).await?;
        if trip.is_none() {
            return Err(anyhow::anyhow!("Trip not found"));
        }

        // Check if tag exists
        let tag = repositories::tags::find_by_id(&self.db, command.tag_id).await?;
        if tag.is_none() {
            return Err(anyhow::anyhow!("Tag not found"));
        }

        repositories::tags::add_tag_to_trip(&self.db, command.trip_id, command.tag_id).await?;
        Ok(())
    }

    pub async fn remove_tag_from_trip(&self, command: RemoveTagFromTrip) -> anyhow::Result<()> {
        repositories::tags::remove_tag_from_trip(&self.db, command.trip_id, command.tag_id).await?;
        Ok(())
    }

    pub async fn set_trip_tags(&self, command: SetTripTags) -> anyhow::Result<()> {
        // Check if trip exists
        let trip = repositories::trips::find_by_id(&self.db, command.trip_id).await?;
        if trip.is_none() {
            return Err(anyhow::anyhow!("Trip not found"));
        }

        // Verify all tags exist
        for tag_id in &command.tag_ids {
            let tag = repositories::tags::find_by_id(&self.db, *tag_id).await?;
            if tag.is_none() {
                return Err(anyhow::anyhow!("Tag with id {} not found", tag_id));
            }
        }

        // Clear existing tags and add new ones
        repositories::tags::clear_trip_tags(&self.db, command.trip_id).await?;
        
        for tag_id in command.tag_ids {
            repositories::tags::add_tag_to_trip(&self.db, command.trip_id, tag_id).await?;
        }

        Ok(())
    }
}
