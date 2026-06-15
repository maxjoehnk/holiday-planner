use std::ops::Deref;
use crate::database::entities::point_of_interest::{self, Entity as PointOfInterest};
use sea_orm::{ActiveValue::Set, EntityTrait, QueryFilter, QueryOrder, ColumnTrait, ConnectionTrait, PaginatorTrait};
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

pub async fn find_unassigned_by_trip(
    db: &Database,
    trip_id: Uuid,
) -> anyhow::Result<Vec<point_of_interest::Model>> {
    let items = PointOfInterest::find()
        .filter(point_of_interest::Column::TripId.eq(trip_id))
        .filter(point_of_interest::Column::TripDayId.is_null())
        .order_by_asc(point_of_interest::Column::Name)
        .all(db.deref())
        .await?;
    Ok(items)
}

pub async fn find_assigned_by_trip(
    db: &Database,
    trip_id: Uuid,
) -> anyhow::Result<Vec<point_of_interest::Model>> {
    let items = PointOfInterest::find()
        .filter(point_of_interest::Column::TripId.eq(trip_id))
        .filter(point_of_interest::Column::TripDayId.is_not_null())
        .order_by_asc(point_of_interest::Column::TripDayId)
        .order_by_asc(point_of_interest::Column::DayOrder)
        .all(db.deref())
        .await?;
    Ok(items)
}

pub async fn assign_to_day(
    db: &Database,
    id: Uuid,
    day_id: Uuid,
    day_order: i32,
    scheduled_at: Option<chrono::DateTime<chrono::Utc>>,
) -> anyhow::Result<()> {
    PointOfInterest::update(point_of_interest::ActiveModel {
        id: Set(id),
        trip_day_id: Set(Some(day_id)),
        day_order: Set(Some(day_order)),
        scheduled_at: Set(scheduled_at),
        ..Default::default()
    })
    .exec(db.deref())
    .await?;
    Ok(())
}

pub async fn unassign(db: &Database, id: Uuid) -> anyhow::Result<()> {
    PointOfInterest::update(point_of_interest::ActiveModel {
        id: Set(id),
        trip_day_id: Set(None),
        day_order: Set(None),
        scheduled_at: Set(None),
        ..Default::default()
    })
    .exec(db.deref())
    .await?;
    Ok(())
}

pub async fn unassign_all_for_days(db: &Database, day_ids: &[Uuid]) -> anyhow::Result<()> {
    if day_ids.is_empty() {
        return Ok(());
    }
    use sea_orm::sea_query::Expr;
    PointOfInterest::update_many()
        .col_expr(point_of_interest::Column::TripDayId, Expr::value(None::<Uuid>))
        .col_expr(point_of_interest::Column::DayOrder, Expr::value(None::<i32>))
        .col_expr(point_of_interest::Column::ScheduledAt, Expr::value(None::<chrono::DateTime<chrono::Utc>>))
        .filter(point_of_interest::Column::TripDayId.is_in(day_ids.to_vec()))
        .exec(db.deref())
        .await?;
    Ok(())
}

pub async fn set_day_order(db: &Database, id: Uuid, day_order: i32) -> anyhow::Result<()> {
    PointOfInterest::update(point_of_interest::ActiveModel {
        id: Set(id),
        day_order: Set(Some(day_order)),
        ..Default::default()
    })
    .exec(db.deref())
    .await?;
    Ok(())
}
