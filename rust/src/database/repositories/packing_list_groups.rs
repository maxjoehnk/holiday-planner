use std::collections::HashMap;
use std::ops::Deref;
use sea_orm::{EntityTrait, ColumnTrait, QueryFilter};
use uuid::Uuid;
use crate::database::Database;
use crate::database::entities::packing_list_group::{self, Entity as PackingListGroup};

pub async fn find_by_name(db: &Database, name: &str) -> anyhow::Result<Option<packing_list_group::Model>> {
    let model = PackingListGroup::find()
        .filter(packing_list_group::Column::Name.eq(name.to_string()))
        .one(db.deref())
        .await?;
    Ok(model)
}

pub async fn find_by_ids(db: &Database, ids: &[Uuid]) -> anyhow::Result<Vec<packing_list_group::Model>> {
    let models = PackingListGroup::find()
        .filter(packing_list_group::Column::Id.is_in(ids.iter().copied().collect::<Vec<_>>()))
        .all(db.deref())
        .await?;
    Ok(models)
}

pub async fn get_or_create_by_name(db: &Database, name: &str) -> anyhow::Result<packing_list_group::Model> {
    if let Some(existing) = find_by_name(db, name).await? {
        return Ok(existing);
    }
    let id = Uuid::new_v4();
    let name = name.to_string();
    insert(db, id, name.clone()).await?;

    Ok(packing_list_group::Model { id, name })
}

async fn insert(db: &Database, id: Uuid, name: String) -> anyhow::Result<()> {
    let new = packing_list_group::ActiveModel {
        id: sea_orm::ActiveValue::set(id),
        name: sea_orm::ActiveValue::Set(name),
    };
    PackingListGroup::insert(new)
        .exec_without_returning(db.deref())
        .await?;
    Ok(())
}

pub fn to_map_by_id(models: Vec<packing_list_group::Model>) -> HashMap<Uuid, packing_list_group::Model> {
    models.into_iter().map(|m| (m.id, m)).collect()
}
