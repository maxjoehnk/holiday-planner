use std::ops::Deref;
use sea_orm::ActiveValue::Set;
use sea_orm::{EntityTrait, QueryFilter, ColumnTrait};
use uuid::Uuid;
use crate::database::Database;
use crate::database::entities::packing_list_condition::{self, Entity as PackingListCondition};

pub async fn insert(db: &Database, packing_list_entry_id: Uuid, mut model: packing_list_condition::ActiveModel) -> anyhow::Result<()> {
    model.packing_list_entry_id = Set(packing_list_entry_id);
    PackingListCondition::insert(model)
        .exec_without_returning(db.deref())
        .await?;

    Ok(())
}

pub async fn delete_by_id(db: &Database, id: Uuid) -> anyhow::Result<()> {
    PackingListCondition::delete_by_id(id)
        .exec(db.deref())
        .await?;

    Ok(())
}

pub async fn delete_by_entry_id(db: &Database, entry_id: Uuid) -> anyhow::Result<()> {
    PackingListCondition::delete_many()
        .filter(packing_list_condition::Column::PackingListEntryId.eq(entry_id))
        .exec(db.deref())
        .await?;

    Ok(())
}
