use uuid::Uuid;
use crate::api::TripPackingListModel;
use crate::database::Database;
use crate::handlers::Handler;

pub struct TripPackingListHandler {
    db: Database,
}

impl Handler for TripPackingListHandler {
    fn create(db: Database) -> Self {
        Self {
            db,
        }
    }
}

impl TripPackingListHandler {
    pub fn get_trip_packing_list(&self, trip_id: Uuid) -> anyhow::Result<TripPackingListModel> {
        let entries = self.db.trip_packing_list_tree()
            .get(&trip_id)?
            .unwrap_or_default();
        let visible = entries.iter()
            .filter(|entry| !entry.explicit_hidden || entry.explicit_shown)
            .cloned()
            .collect();
        let hidden = entries.iter()
            .filter(|entry| entry.explicit_hidden || !entry.explicit_shown)
            .cloned()
            .collect();

        Ok(TripPackingListModel {
            visible,
            hidden,
        })
    }

    pub fn mark_as_packed(&self, trip_id: Uuid, entry_id: Uuid) -> anyhow::Result<()> {
        self.db.trip_packing_list_tree()
            .update_and_fetch(&trip_id, |trip_packing_list| {
                let mut trip_packing_list = trip_packing_list.unwrap_or_default();
                for entry in trip_packing_list.iter_mut() {
                    if entry.packing_list_entry.id == entry_id {
                        entry.is_packed = true;
                    }
                }

                Some(trip_packing_list)
            })?;

        Ok(())
    }

    pub fn mark_as_unpacked(&self, trip_id: Uuid, entry_id: Uuid) -> anyhow::Result<()> {
        self.db.trip_packing_list_tree()
            .update_and_fetch(&trip_id, |trip_packing_list| {
                let mut trip_packing_list = trip_packing_list.unwrap_or_default();
                for entry in trip_packing_list.iter_mut() {
                    if entry.packing_list_entry.id == entry_id {
                        entry.is_packed = false;
                    }
                }

                Some(trip_packing_list)
            })?;

        Ok(())
    }
}
