use sea_orm::ActiveValue::Set;
use sea_orm::IntoActiveModel;
use uuid::Uuid;
use crate::commands::{AddTripPointOfInterest, UpdateTripPointOfInterest};
use crate::database::{Database, entities, repositories};
use crate::handlers::Handler;
use crate::models::{PointOfInterestModel, TripAttachment};

pub struct PointOfInterestHandler {
    db: Database,
}

impl Handler for PointOfInterestHandler {
    fn create(db: Database) -> Self {
        Self {
            db,
        }
    }
}

impl PointOfInterestHandler {
    pub async fn add_point_of_interest(&self, command: AddTripPointOfInterest) -> anyhow::Result<()> {
        tracing::debug!("Adding point of interest to trip {}", command.trip_id);
        
        let point_of_interest = entities::point_of_interest::ActiveModel {
            id: Set(Uuid::new_v4()),
            trip_id: Set(command.trip_id),
            name: Set(command.name),
            address: Set(command.address),
            website: Set(command.website),
            opening_hours: Set(command.opening_hours),
            price: Set(command.price),
            phone_number: Set(command.phone_number),
            note: Set(command.note),
        };
        
        repositories::points_of_interest::insert(&self.db, point_of_interest).await?;

        Ok(())
    }
    
    pub async fn get_trip_points_of_interest(&self, trip_id: Uuid) -> anyhow::Result<Vec<PointOfInterestModel>> {
        let points_of_interest = repositories::points_of_interest::find_all_by_trip(&self.db, trip_id).await?;
        let points_of_interest = points_of_interest.into_iter().map(|p| PointOfInterestModel {
            id: p.id,
            name: p.name,
            address: p.address,
            website: p.website,
            opening_hours: p.opening_hours,
            price: p.price,
            phone_number: p.phone_number,
            note: p.note,
        }).collect();
        
        Ok(points_of_interest)
    }

    pub async fn update_point_of_interest(&self, command: UpdateTripPointOfInterest) -> anyhow::Result<()> {
        let Some(point_of_interest) = repositories::points_of_interest::find_by_id(&self.db, command.id).await? else {
            anyhow::bail!("Unknown point of interest");
        };
        let mut point_of_interest = point_of_interest.into_active_model();
        point_of_interest.name.set_if_not_equals(command.name);
        point_of_interest.address.set_if_not_equals(command.address);
        point_of_interest.website.set_if_not_equals(command.website);
        point_of_interest.opening_hours.set_if_not_equals(command.opening_hours);
        point_of_interest.price.set_if_not_equals(command.price);
        point_of_interest.phone_number.set_if_not_equals(command.phone_number);
        point_of_interest.note.set_if_not_equals(command.note);

        repositories::points_of_interest::update(&self.db, point_of_interest).await?;

        Ok(())
    }

    pub async fn delete_point_of_interest(&self, point_of_interest_id: Uuid) -> anyhow::Result<()> {
        repositories::points_of_interest::delete_by_id(&self.db, point_of_interest_id).await?;

        Ok(())
    }
}
