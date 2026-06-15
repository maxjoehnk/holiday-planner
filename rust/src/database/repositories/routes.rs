use std::ops::Deref;

use sea_orm::{ActiveValue::Set, ColumnTrait, ConnectionTrait, EntityTrait, PaginatorTrait, QueryFilter, QueryOrder};
use uuid::Uuid;

use crate::database::entities::route::{self, Entity as Route, RouteProvider};
use crate::database::{Database, DbResult};

pub async fn count_by_trip(db: &impl ConnectionTrait, trip_id: Uuid) -> DbResult<u64> {
    let count = Route::find()
        .filter(route::Column::TripId.eq(trip_id))
        .count(db)
        .await?;

    Ok(count)
}

pub async fn find_all_by_trip(db: &Database, trip_id: Uuid) -> anyhow::Result<Vec<route::Model>> {
    let routes = Route::find()
        .filter(route::Column::TripId.eq(trip_id))
        .order_by_asc(route::Column::Name)
        .all(db.deref())
        .await?;

    Ok(routes)
}

pub async fn find_by_id(db: &Database, id: Uuid) -> anyhow::Result<Option<route::Model>> {
    let route = Route::find_by_id(id).one(db.deref()).await?;

    Ok(route)
}

pub async fn find_by_provider_route(
    db: &Database,
    trip_id: Uuid,
    provider: RouteProvider,
    provider_route_id: &str,
) -> anyhow::Result<Option<route::Model>> {
    let route = Route::find()
        .filter(route::Column::TripId.eq(trip_id))
        .filter(route::Column::Provider.eq(provider))
        .filter(route::Column::ProviderRouteId.eq(provider_route_id))
        .one(db.deref())
        .await?;

    Ok(route)
}

pub async fn insert(db: &Database, model: route::ActiveModel) -> anyhow::Result<()> {
    Route::insert(model)
        .exec_without_returning(db.deref())
        .await?;

    Ok(())
}

pub async fn update(db: &Database, model: route::ActiveModel) -> anyhow::Result<()> {
    Route::update(model).exec(db.deref()).await?;

    Ok(())
}

pub async fn delete_by_id(db: &Database, id: Uuid) -> anyhow::Result<()> {
    Route::delete_by_id(id).exec(db.deref()).await?;

    Ok(())
}

pub async fn find_unassigned_by_trip(
    db: &Database,
    trip_id: Uuid,
) -> anyhow::Result<Vec<route::Model>> {
    let items = Route::find()
        .filter(route::Column::TripId.eq(trip_id))
        .filter(route::Column::TripDayId.is_null())
        .order_by_asc(route::Column::Name)
        .all(db.deref())
        .await?;
    Ok(items)
}

pub async fn find_assigned_by_trip(
    db: &Database,
    trip_id: Uuid,
) -> anyhow::Result<Vec<route::Model>> {
    let items = Route::find()
        .filter(route::Column::TripId.eq(trip_id))
        .filter(route::Column::TripDayId.is_not_null())
        .order_by_asc(route::Column::TripDayId)
        .order_by_asc(route::Column::DayOrder)
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
    Route::update(route::ActiveModel {
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
    Route::update(route::ActiveModel {
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
    Route::update_many()
        .col_expr(route::Column::TripDayId, Expr::value(None::<Uuid>))
        .col_expr(route::Column::DayOrder, Expr::value(None::<i32>))
        .col_expr(route::Column::ScheduledAt, Expr::value(None::<chrono::DateTime<chrono::Utc>>))
        .filter(route::Column::TripDayId.is_in(day_ids.to_vec()))
        .exec(db.deref())
        .await?;
    Ok(())
}

pub async fn set_day_order(db: &Database, id: Uuid, day_order: i32) -> anyhow::Result<()> {
    Route::update(route::ActiveModel {
        id: Set(id),
        day_order: Set(Some(day_order)),
        ..Default::default()
    })
    .exec(db.deref())
    .await?;
    Ok(())
}
