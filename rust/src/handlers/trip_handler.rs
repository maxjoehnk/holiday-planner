use sea_orm::ActiveValue::Set;
use uuid::Uuid;
use crate::database::{Database, repositories, entities};
use crate::models::*;
use crate::commands::*;
use crate::handlers::{Handler, TripPackingListHandler};

pub struct TripHandler {
    db: Database,
}

impl Handler for TripHandler {
    fn create(db: Database) -> Self {
        Self {
            db,
        }
    }
}

impl TripHandler {
    pub async fn get_trips(&self) -> anyhow::Result<Vec<TripListModel>> {
        tracing::debug!("Getting trips");
        let trips = repositories::trips::find_all(&self.db).await?;

        let trips = trips.into_iter()
            .map(|trip| TripListModel {
                id: trip.id,
                name: trip.name,
                start_date: trip.start_date,
                end_date: trip.end_date,
                header_image: trip.header_image,
            })
            .collect();

        Ok(trips)
    }

    pub async fn get_trip_overview(&self, id: Uuid) -> anyhow::Result<Option<TripOverviewModel>> {
        let trip = repositories::trips::find_by_id(&self.db, id).await?;
        
        // TODO: we should not depend upon another handler
        // Also we don't need to fetch all the packing list items for the overview
        let trip_packing_list_handler = TripPackingListHandler::create(self.db.clone());
        let packing_items = trip_packing_list_handler.get_trip_packing_list(id).await?;
        let pending_packing_list_items = packing_items.entries.iter().filter(|entry| !entry.is_packed).count();
        let packed_packing_list_items = packing_items.entries.iter().filter(|entry| entry.is_packed).count();
        let total_packing_list_items = packing_items.entries.len();
        
        let trip = trip.map(|trip| {
            TripOverviewModel {
                id: trip.id,
                name: trip.name,
                header_image: trip.header_image,
                pending_packing_list_items,
                total_packing_list_items,
                packed_packing_list_items,
            }
        });

        Ok(trip)
    }

    pub async fn create_trip(&self, command: CreateTrip) -> anyhow::Result<TripOverviewModel> {
        let model = entities::trip::ActiveModel {
            name: Set(command.name),
            start_date: Set(command.start_date),
            end_date: Set(command.end_date),
            header_image: Set(command.header_image),
            ..Default::default()
        };
        let trip = repositories::trips::create(&self.db, model).await?;
        let trip = self.get_trip_overview(trip.id).await?.unwrap();

        Ok(trip)
    }
}
