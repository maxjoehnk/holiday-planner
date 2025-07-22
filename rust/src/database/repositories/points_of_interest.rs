use std::ops::Deref;
use crate::database::entities::point_of_interest::{self, Entity as PointOfInterest};
use sea_orm::{EntityTrait, QueryFilter, QueryOrder, ColumnTrait, ConnectionTrait, PaginatorTrait};
use uuid::Uuid;
use crate::database::{Database, DbResult};

pub async fn count_by_trip(db: &impl ConnectionTrait, trip_id: Uuid) -> DbResult<u64> {
    let count = PointOfInterest::find()
        .filter(point_of_interest::Column::TripId.eq(trip_id))
        .count(db)
        .await?;

    Ok(count)
}

pub async fn find_all_by_trip(db: &Database, trip_id: Uuid) -> anyhow::Result<Vec<point_of_interest::Model>> {
    let points_of_interest = PointOfInterest::find()
        .filter(point_of_interest::Column::TripId.eq(trip_id))
        .order_by_asc(point_of_interest::Column::Name)
        .all(db.deref())
        .await?;

    Ok(points_of_interest)
}

pub async fn find_by_id(db: &Database, id: Uuid) -> anyhow::Result<Option<point_of_interest::Model>> {
    let point_of_interest = PointOfInterest::find_by_id(id)
        .one(db.deref())
        .await?;

    Ok(point_of_interest)
}

pub async fn insert(db: &Database, model: point_of_interest::ActiveModel) -> anyhow::Result<()> {
    PointOfInterest::insert(model)
        .exec_without_returning(db.deref())
        .await?;
    
    Ok(())
}

pub async fn update(db: &Database, model: point_of_interest::ActiveModel) -> anyhow::Result<()> {
    PointOfInterest::update(model)
        .exec(db.deref())
        .await?;
    
    Ok(())
}

pub async fn delete_by_id(db: &Database, id: Uuid) -> anyhow::Result<()> {
    PointOfInterest::delete_by_id(id)
        .exec(db.deref())
        .await?;

    Ok(())
}
