use sea_orm::ActiveValue::Set;
use sea_orm::IntoActiveModel;
use uuid::Uuid;
use crate::models::{TripPackingListEntry, TripPackingListModel};
use crate::database::entities::{trip_packing_list_entry, packing_list_entry};
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

        let raw: Vec<(trip_packing_list_entry::Model, packing_list_entry::Model)> = trip_packing_list_entries
            .into_iter()
            .filter_map(|(entry, packing_list_entry)| Some((entry, packing_list_entry?)))
            .collect();

        let mut group_ids: Vec<uuid::Uuid> = raw.iter().filter_map(|(_, ple)| ple.group_id).collect();
        group_ids.sort();
        group_ids.dedup();

        let groups_models = repositories::packing_list_groups::find_by_ids(&self.db, &group_ids).await?;
        let groups_map = repositories::packing_list_groups::to_map_by_id(groups_models);

        let mut entries: Vec<TripPackingListEntry> = raw
            .into_iter()
            .map(|(entry, ple)| {
                let category = ple.group_id.and_then(|id| groups_map.get(&id).map(|g| g.name.clone()));
                let model_entry = crate::models::PackingListEntry {
                    id: ple.id,
                    name: ple.name,
                    description: ple.description,
                    conditions: Default::default(),
                    quantity: crate::models::Quantity {
                        per_day: ple.quantity_per_day.map(|q| q as usize),
                        per_night: ple.quantity_per_night.map(|q| q as usize),
                        fixed: ple.quantity_fixed.map(|q| q as usize),
                    },
                    category,
                };
                TripPackingListEntry {
                    packing_list_entry: model_entry,
                    is_packed: entry.is_packed,
                    // The quantity is calculated by a background job
                    quantity: entry.override_quantity.or(entry.quantity).map(|q| q as usize),
                }
            })
            .collect();

        use std::collections::BTreeMap;
        let mut grouped: BTreeMap<(uuid::Uuid, String), Vec<TripPackingListEntry>> = BTreeMap::new();
        let mut uncategorized: Vec<TripPackingListEntry> = Vec::new();
        for e in entries.into_iter() {
            if let Some(cat_name) = &e.packing_list_entry.category {
                let (gid, _) = groups_map
                    .iter()
                    .find(|(_, g)| &g.name == cat_name)
                    .map(|(id, g)| (*id, g.name.clone()))
                    .unwrap_or((Uuid::new_v4(), cat_name.clone()));
                grouped.entry((gid, cat_name.clone())).or_default().push(e);
            } else {
                uncategorized.push(e);
            }
        }

        let mut groups: Vec<crate::models::TripPackingListGroup> = grouped
            .into_iter()
            .map(|((id, name), mut entries)| {
                entries.sort_by(|a, b| a.packing_list_entry.name.to_lowercase().cmp(&b.packing_list_entry.name.to_lowercase()));
                crate::models::TripPackingListGroup { id, name, entries }
            })
            .collect();
        groups.sort_by(|a, b| a.name.to_lowercase().cmp(&b.name.to_lowercase()));

        uncategorized.sort_by(|a, b| a.packing_list_entry.name.to_lowercase().cmp(&b.packing_list_entry.name.to_lowercase()));

        Ok(TripPackingListModel {
            entries: uncategorized,
            groups,
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
