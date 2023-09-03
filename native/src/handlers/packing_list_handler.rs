use uuid::Uuid;
use crate::database::Database;
use crate::models::*;
use crate::commands::*;
use crate::handlers::Handler;

pub struct PackingListHandler {
    db: Database,
}

impl Handler for PackingListHandler {
    fn create(db: Database) -> Self {
        Self {
            db,
        }
    }
}

impl PackingListHandler {
    pub fn get_packing_list(&self) -> anyhow::Result<Vec<PackingListEntry>> {
        let packing_list = self.db.packing_list_tree()
            .iter()
            .values()
            .collect::<Result<_, _>>()?;

        Ok(packing_list)
    }

    pub fn add_packing_list_entry(&self, command: AddPackingListEntry) -> anyhow::Result<PackingListEntry> {
        let entry = PackingListEntry {
            id: Uuid::new_v4(),
            name: command.name,
            conditions: command.conditions,
            quantity: command.quantity,
        };
        self.db.packing_list_tree().insert(&entry.id, &entry)?;
        for trip in self.db.trip_tree().iter().values() {
            let trip = trip?;
            self.db.trip_packing_list_tree()
                .update_and_fetch(&trip.id, |trip_packing_list| {
                    let mut trip_packing_list = trip_packing_list.unwrap_or_default();
                    trip_packing_list.push(TripPackingListEntry::from_entry(&trip, entry.clone()));

                    Some(trip_packing_list)
                })?;
        }

        Ok(entry)
    }

    pub fn delete_packing_list_entry(&self, command: DeletePackingListEntry) -> anyhow::Result<()> {
        self.db.packing_list_tree().remove(&command.id)?;

        Ok(())
    }
}
