use std::collections::HashMap;
use sea_orm::ActiveValue::Set;
use sea_orm::{IntoActiveModel, TransactionTrait};
use crate::database::{Database, repositories, entities};
use crate::database::entities::trip::Model as Trip;
use crate::jobs::Job;
use crate::models::{PackingListEntry, PackingListEntryCondition};

pub struct PackingListUpdateJob {
    db: Database,
}

impl PackingListUpdateJob {
    pub fn new(db: Database) -> Self {
        Self {
            db,
        }
    }
}

impl Job for PackingListUpdateJob {
    async fn run(&self) -> anyhow::Result<()> {
        tracing::info!("Running packing list job");
        let packing_list_entries = repositories::packing_list_entries::find_all(&self.db).await?;
        let packing_list_entries = packing_list_entries.into_iter().map(PackingListEntry::from).collect::<Vec<_>>();
        let trips = repositories::trips::find_all(&self.db).await?;
        for trip in trips {
            tracing::debug!("Updating packing list for trip {}", trip.name);
            let packing_entries = repositories::trip_packing_list_entries::find_trip_entries_by_trip(&self.db, trip.id).await?;
            let mut packing_entries = packing_entries.into_iter()
                .map(|entry| (entry.packing_list_entry_id, entry.into_active_model()))
                .collect::<HashMap<_, _>>();
            for packing_list_entry in &packing_list_entries {
                if packing_list_entry.conditions.iter().any(|condition| condition.matches(&trip)) {
                    let quantity = packing_list_entry.quantity.calculate(trip.start_date, trip.end_date);
                    if let Some(mut model) = packing_entries.remove(&packing_list_entry.id) {
                        model.quantity = Set(quantity.map(|q| q as i64));
                        repositories::trip_packing_list_entries::update(&self.db, trip.id, model).await?;
                    }else {
                        let model = entities::trip_packing_list_entry::ActiveModel {
                            packing_list_entry_id: Set(packing_list_entry.id),
                            trip_id: Set(trip.id),
                            quantity: Set(quantity.map(|q| q as i64)),
                            ..Default::default()
                        };
                        repositories::trip_packing_list_entries::insert(&self.db, model).await?;
                    }
                }
            }
            let entries_to_be_removed = packing_entries.into_iter().map(|(id, _)| id).collect::<Vec<_>>();
            repositories::trip_packing_list_entries::delete_many_by_ids(&self.db, trip.id, entries_to_be_removed).await?;
        }

        tracing::info!("Finished packing list job");

        Ok(())
    }
}

impl PackingListEntryCondition {
    pub(crate) fn matches(&self, trip: &Trip) -> bool {
        match self {
            Self::MinTripDuration { length } => {
                let duration = trip.end_date.signed_duration_since(trip.start_date);
                let days = duration.num_days() as usize;

                (*length as usize) <= days
            }
            Self::MaxTripDuration { length } => {
                let duration = trip.end_date.signed_duration_since(trip.start_date);
                let days = duration.num_days() as usize;

                (*length as usize) > days
            }
            _ => false,
        }
    }
}
