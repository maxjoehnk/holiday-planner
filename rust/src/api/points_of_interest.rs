use uuid::Uuid;
use crate::api::DB;
use crate::commands::{AddTripPointOfInterest, UpdateTripPointOfInterest};
use crate::handlers::{PointOfInterestHandler, HandlerCreator};
use crate::models::{PointOfInterestModel};
use crate::models::point_of_interests::{PointOfInterestOsmModel, PointOfInterestSearchModel};

#[tracing::instrument]
pub async fn search_point_of_interests(query: String, trip_id: Uuid) -> anyhow::Result<Vec<PointOfInterestSearchModel>> {
    let handler = DB.try_get::<PointOfInterestHandler>().await?;
    handler.search_point_of_interest(trip_id, query).await
}

#[tracing::instrument]
pub async fn search_point_of_interest_details(id: u64) -> anyhow::Result<PointOfInterestOsmModel> {
    let handler = DB.try_get::<PointOfInterestHandler>().await?;
    handler.search_point_of_interest_details(id).await
}

#[tracing::instrument]
pub async fn get_trip_points_of_interest(trip_id: Uuid) -> anyhow::Result<Vec<PointOfInterestModel>> {
    let handler = DB.try_get::<PointOfInterestHandler>().await?;
    handler.get_trip_points_of_interest(trip_id).await
}

#[tracing::instrument]
pub async fn add_trip_point_of_interest(command: AddTripPointOfInterest) -> anyhow::Result<()> {
    let handler = DB.try_get::<PointOfInterestHandler>().await?;
    handler.add_point_of_interest(command).await
}

#[tracing::instrument]
pub async fn update_trip_point_of_interest(command: UpdateTripPointOfInterest) -> anyhow::Result<()> {
    let handler = DB.try_get::<PointOfInterestHandler>().await?;
    handler.update_point_of_interest(command).await
}

#[tracing::instrument]
pub async fn delete_point_of_interest(point_of_interest_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<PointOfInterestHandler>().await?;
    handler.delete_point_of_interest(point_of_interest_id).await
}
