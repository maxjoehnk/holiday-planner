use std::ops::Deref;

use sea_orm::{ColumnTrait, EntityTrait, QueryFilter, QueryOrder};
use uuid::Uuid;

use crate::database::entities::route::{self, Entity as Route, RouteProvider};
use crate::database::Database;

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
