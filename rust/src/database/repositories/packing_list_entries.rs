use std::ops::Deref;
use sea_orm::{EntityTrait, ColumnTrait, QueryFilter};
use uuid::Uuid;
use crate::database::Database;
use crate::database::entities::packing_list_entry::{self, Entity as PackingListEntry};
use crate::database::entities::packing_list_condition::{self, Entity as PackingListCondition};

pub async fn find_all(db: &Database) -> anyhow::Result<Vec<(packing_list_entry::Model, Vec<packing_list_condition::Model>)>> {
    let packing_list_entries = PackingListEntry::find()
        .find_with_related(PackingListCondition)
        .all(db.deref())
        .await?;

    Ok(packing_list_entries)
}

pub async fn find_by_id(db: &Database, id: Uuid) -> anyhow::Result<Option<packing_list_entry::Model>> {
    let packing_list_entry = PackingListEntry::find()
        .filter(packing_list_entry::Column::Id.eq(id))
        .one(db.deref())
        .await?;

    Ok(packing_list_entry)
}

pub async fn insert(db: &Database, model: packing_list_entry::ActiveModel) -> anyhow::Result<()> {
    PackingListEntry::insert(model)
        .exec_without_returning(db.deref())
        .await?;

    Ok(())
}

pub async fn update(db: &Database, model: packing_list_entry::ActiveModel) -> anyhow::Result<()> {
    PackingListEntry::update(model)
        .exec(db.deref())
        .await?;

    Ok(())
}

pub async fn delete_by_id(db: &Database, id: Uuid) -> anyhow::Result<()> {
    PackingListEntry::delete_by_id(id)
        .exec(db.deref())
        .await?;

    Ok(())
}
