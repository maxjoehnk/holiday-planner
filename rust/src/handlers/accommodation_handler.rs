use sea_orm::ActiveValue::Set;
use uuid::Uuid;
use crate::commands::{AddTripAccommodation};
use crate::database::{Database, entities, repositories};
use crate::handlers::Handler;
use crate::models::{AccommodationModel};

pub struct AccommodationHandler {
    db: Database,
}

impl Handler for AccommodationHandler {
    fn create(db: Database) -> Self {
        Self {
            db,
        }
    }
}

impl AccommodationHandler {
    pub async fn add_accommodation(&self, command: AddTripAccommodation) -> anyhow::Result<()> {
        tracing::debug!("Adding accommodation to trip {}", command.trip_id);
        
        let accommodation = entities::accommodation::ActiveModel {
            id: Set(Uuid::new_v4()),
            trip_id: Set(command.trip_id),
            name: Set(command.name),
            address: Set(command.address),
            check_in: Set(command.check_in),
            check_out: Set(command.check_out),
        };
        
        repositories::accommodations::insert(&self.db, accommodation).await?;

        Ok(())
    }
    
    pub async fn get_trip_accommodations(&self, trip_id: Uuid) -> anyhow::Result<Vec<AccommodationModel>> {
        let accommodations = repositories::accommodations::find_all_by_trip(&self.db, trip_id).await?;
        let accommodations = accommodations.into_iter().map(|accommodation| AccommodationModel {
            id: accommodation.id,
            name: accommodation.name,
            check_in: accommodation.check_in.unwrap(), // TODO: update database schema
            check_out: accommodation.check_out.unwrap(),
            address: accommodation.address,
            attachments: vec![],
        }).collect();
        
        Ok(accommodations)
    }

    pub async fn delete_accommodation(&self, accommodation_id: Uuid) -> anyhow::Result<()> {
        repositories::accommodations::delete_by_id(&self.db, accommodation_id).await?;

        Ok(())
    }
}
