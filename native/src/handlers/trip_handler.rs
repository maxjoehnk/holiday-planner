use uuid::Uuid;
use crate::database::Database;
use crate::models::*;
use crate::commands::*;
use crate::handlers::Handler;
use crate::handlers::packing_list_handler::PackingListHandler;

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
    pub fn get_trips(&self) -> anyhow::Result<Vec<Trip>> {
        tracing::debug!("Getting trips");
        let trips = self.db.trip_tree()
            .iter()
            .values()
            .collect::<Result<_, _>>()?;

        Ok(trips)
    }

    pub fn create_trip(&self, command: CreateTrip) -> anyhow::Result<Trip> {
        let trip = Trip {
            id: Uuid::new_v4(),
            name: command.name,
            start_date: command.start_date,
            end_date: command.end_date,
            header_image: command.header_image,
            locations: Default::default(),
            attachments: Default::default(),
        };
        self.db.trip_tree().insert(&trip.id, &trip)?;
        let packing_list = PackingListHandler::create(self.db.clone()).get_packing_list()?;
        let packing_list = packing_list.into_iter()
            .map(|entry| TripPackingListEntry::from_entry(&trip, entry))
            .collect();
        self.db.trip_packing_list_tree().insert(&trip.id, &packing_list)?;

        Ok(trip)
    }

    pub fn add_trip_location(&self, trip_id: Uuid, location: LocationEntry) -> anyhow::Result<()> {
        let location = Location {
            coordinates: location.coordinates,
            country: location.country,
            city: location.name,
            attachments: Default::default(),
            forecast: None,
        };
        self.db.trip_tree()
            .update_and_fetch(&trip_id, |trip| {
                let mut trip = trip.unwrap();
                trip.locations.push(location.clone());

                Some(trip)
            })?;

        Ok(())
    }
}
