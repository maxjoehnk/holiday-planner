use std::ops::Deref;
use crate::database::entities::trip::{self, Entity as Trip};
use sea_orm::{EntityTrait, QueryOrder};
use sea_orm::ActiveValue::Set;
use uuid::Uuid;
use crate::database::Database;

pub async fn find_all(db: &Database) -> anyhow::Result<Vec<trip::Model>> {
    let trips = Trip::find()
        .order_by_asc(trip::Column::StartDate)
        .all(db.deref())
        .await?;

    Ok(trips)
}

pub async fn find_by_id(db: &Database, id: Uuid) -> anyhow::Result<Option<trip::Model>> {
    let trip = Trip::find_by_id(id)
        .one(db.deref())
        .await?;

    Ok(trip)
}

pub async fn create(db: &Database, mut model: trip::ActiveModel) -> anyhow::Result<trip::Model> {
    let id = Uuid::new_v4();
    model.id = Set(id);
    Trip::insert(model)
        .exec_without_returning(db.deref())
        .await?;

    let trip = Trip::find_by_id(id)
        .one(db.deref())
        .await?
        .unwrap();

    Ok(trip)
}
