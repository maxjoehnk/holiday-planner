use sea_orm::ActiveValue::Set;
use sea_orm::IntoActiveModel;
use uuid::Uuid;
use crate::models::{TripPackingListEntry, TripPackingListModel};
use crate::database::{Database, repositories};
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
    pub async fn get_trip_packing_list(&self, trip_id: Uuid) -> anyhow::Result<TripPackingListModel> {
        let trip_packing_list_entries = repositories::trip_packing_list_entries::find_packing_list_entries_by_trip(&self.db, trip_id).await?;

        let entries = trip_packing_list_entries
            .into_iter()
            .filter_map(|(entry, packing_list_entry)| {
                let packing_list_entry = packing_list_entry?;

                Some(TripPackingListEntry {
                    packing_list_entry: packing_list_entry.into(),
                    is_packed: entry.is_packed,
                    // The quantity is calculated by a background job
                    quantity: entry.override_quantity.or(entry.quantity).map(|q| q as usize),
                })
            })
            .collect();

        Ok(TripPackingListModel {
            entries,
            groups: Default::default()
        })
    }

    pub async fn mark_as_packed(&self, trip_id: Uuid, entry_id: Uuid) -> anyhow::Result<()> {
        let entry = repositories::trip_packing_list_entries::find_by_id(&self.db, trip_id, entry_id).await?;

        if let Some(entry) = entry {
            let mut entry = entry.into_active_model();
            entry.is_packed = Set(true);
            repositories::trip_packing_list_entries::update(&self.db, trip_id, entry).await?;
        }

        Ok(())
    }

    pub async fn mark_as_unpacked(&self, trip_id: Uuid, entry_id: Uuid) -> anyhow::Result<()> {
        let entry = repositories::trip_packing_list_entries::find_by_id(&self.db, trip_id, entry_id).await?;

        if let Some(entry) = entry {
            let mut entry = entry.into_active_model();
            entry.is_packed = Set(false);
            repositories::trip_packing_list_entries::update(&self.db, trip_id, entry).await?;
        }

        Ok(())
    }
}
