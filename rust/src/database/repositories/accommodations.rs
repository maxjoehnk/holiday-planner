use std::ops::Deref;
use crate::database::entities::accommodation::{self, Entity as Accommodation};
use sea_orm::{EntityTrait, QueryFilter, QueryOrder, ColumnTrait};
use uuid::Uuid;
use crate::database::Database;

pub async fn find_all_by_trip(db: &Database, trip_id: Uuid) -> anyhow::Result<Vec<accommodation::Model>> {
    let attachments = Accommodation::find()
        .filter(accommodation::Column::TripId.eq(trip_id))
        .order_by_asc(accommodation::Column::Name)
        .all(db.deref())
        .await?;

    Ok(attachments)
}

pub async fn find_by_id(db: &Database, id: Uuid) -> anyhow::Result<Option<accommodation::Model>> {
    let attachment = Accommodation::find_by_id(id)
        .one(db.deref())
        .await?;

    Ok(attachment)
}

pub async fn insert(db: &Database, model: accommodation::ActiveModel) -> anyhow::Result<()> {
    Accommodation::insert(model)
        .exec_without_returning(db.deref())
        .await?;
    
    Ok(())
}

pub async fn update(db: &Database, model: accommodation::ActiveModel) -> anyhow::Result<()> {
    Accommodation::update(model)
        .exec(db.deref())
        .await?;
    
    Ok(())
}

pub async fn delete_by_id(db: &Database, id: Uuid) -> anyhow::Result<()> {
    Accommodation::delete_by_id(id)
        .exec(db.deref())
        .await?;

    Ok(())
}
