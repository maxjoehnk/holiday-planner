use uuid::Uuid;
use super::DB;
use crate::handlers::*;
use crate::handlers::timeline_handler::TimelineHandler;
use crate::models::timeline::TimelineModel;

#[tracing::instrument]
pub async fn get_trip_timeline(trip_id: Uuid) -> anyhow::Result<TimelineModel> {
    let handler = DB.try_get::<TimelineHandler>().await?;
    handler.get_timeline(trip_id).await
}
