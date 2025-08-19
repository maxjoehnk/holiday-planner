use std::ops::Deref;
use sea_orm::{EntityTrait, QueryFilter, ColumnTrait, PaginatorTrait, ModelTrait};
use uuid::Uuid;
use crate::database::Database;
use crate::database::entities::trip_packing_list_entry::{self, Entity as TripPackingListEntry};
use crate::database::entities::packing_list_entry::{self, Entity as PackingListEntry};

pub async fn find_trip_entries_by_trip(db: &Database, trip_id: Uuid) -> anyhow::Result<Vec<trip_packing_list_entry::Model>> {
    let packing_list_entries = TripPackingListEntry::find()
        .filter(trip_packing_list_entry::Column::TripId.eq(trip_id))
        .all(db.deref())
        .await?;

    Ok(packing_list_entries)
}

pub async fn find_packing_list_entries_by_trip(db: &Database, trip_id: Uuid) -> anyhow::Result<Vec<(trip_packing_list_entry::Model, Option<packing_list_entry::Model>)>> {
    let packing_list_entries = TripPackingListEntry::find()
        .filter(trip_packing_list_entry::Column::TripId.eq(trip_id))
        .find_also_related(PackingListEntry)
        .all(db.deref())
        .await?;

    Ok(packing_list_entries)
}

pub async fn count_by_trip(db: &Database, trip_id: Uuid) -> anyhow::Result<usize> {
    let count = TripPackingListEntry::find()
        .filter(trip_packing_list_entry::Column::TripId.eq(trip_id))
        .count(db.deref())
        .await?;

    Ok(count as usize)
}

pub async fn count_pending_by_trip(db: &Database, trip_id: Uuid) -> anyhow::Result<usize> {
    let count = TripPackingListEntry::find()
        .filter(trip_packing_list_entry::Column::TripId.eq(trip_id).and(trip_packing_list_entry::Column::IsPacked.eq(false)))
        .count(db.deref())
        .await?;

    Ok(count as usize)
}

pub async fn insert(db: &Database, model: trip_packing_list_entry::ActiveModel) -> anyhow::Result<()> {
    TripPackingListEntry::insert(model)
        .exec_without_returning(db.deref())
        .await?;
    
    Ok(())
}

pub async fn find_by_id(db: &Database, trip_id: Uuid, id: Uuid) -> anyhow::Result<Option<trip_packing_list_entry::Model>> {
    let packing_list_entry = TripPackingListEntry::find_by_id((trip_id, id))
        .one(db.deref())
        .await?;

    Ok(packing_list_entry)
}

pub async fn update(db: &Database, trip_id: Uuid, model: trip_packing_list_entry::ActiveModel) -> anyhow::Result<()> {
    TripPackingListEntry::update(model)
        .filter(trip_packing_list_entry::Column::TripId.eq(trip_id))
        .exec(db.deref())
        .await?;

    Ok(())
}

pub async fn delete_many_by_ids(db: &Database, trip_id: Uuid, ids: Vec<Uuid>) -> anyhow::Result<()> {
    TripPackingListEntry::delete_many()
        .filter(trip_packing_list_entry::Column::PackingListEntryId.is_in(ids))
        .filter(trip_packing_list_entry::Column::TripId.eq(trip_id))
        .exec(db.deref())
        .await?;

    Ok(())
}
