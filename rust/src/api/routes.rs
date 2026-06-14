use uuid::Uuid;

use crate::api::events::{self, DataChangeEvent};
use crate::api::DB;
use crate::commands::{ImportKomootRoute, UpdateRoute};
use crate::handlers::{HandlerCreator, RouteHandler};
use crate::models::RouteModel;

#[tracing::instrument]
pub async fn import_komoot_route(command: ImportKomootRoute) -> anyhow::Result<RouteModel> {
    let handler = DB.try_get::<RouteHandler>().await?;
    let trip_id = command.trip_id;
    let route = handler.import_komoot_route(command).await?;
    events::emit(DataChangeEvent::RoutesChanged {
        trip_id: Some(trip_id),
    });
    Ok(route)
}

#[tracing::instrument]
pub async fn get_trip_routes(trip_id: Uuid) -> anyhow::Result<Vec<RouteModel>> {
    let handler = DB.try_get::<RouteHandler>().await?;
    handler.get_trip_routes(trip_id).await
}

#[tracing::instrument]
pub async fn update_route(command: UpdateRoute) -> anyhow::Result<()> {
    let handler = DB.try_get::<RouteHandler>().await?;
    handler.update_route(command).await?;
    events::emit(DataChangeEvent::RoutesChanged { trip_id: None });
    Ok(())
}

#[tracing::instrument]
pub async fn delete_route(route_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<RouteHandler>().await?;
    handler.delete_route(route_id).await?;
    events::emit(DataChangeEvent::RoutesChanged { trip_id: None });
    Ok(())
}
