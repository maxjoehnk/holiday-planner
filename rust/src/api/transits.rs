use uuid::Uuid;
use crate::api::DB;
use crate::commands::{AddTrain, UpdateTrain};
use crate::handlers::{HandlerCreator, TrainHandler};
use crate::models::Train;

#[tracing::instrument]
pub async fn add_train(command: AddTrain) -> anyhow::Result<()> {
    let handler = DB.try_get::<TrainHandler>().await?;
    handler.add_train(command).await
}

#[tracing::instrument]
pub async fn update_train(command: UpdateTrain) -> anyhow::Result<()> {
    let handler = DB.try_get::<TrainHandler>().await?;
    handler.update_train(command).await
}

#[tracing::instrument]
pub async fn delete_train(train_id: Uuid) -> anyhow::Result<()> {
    let handler = DB.try_get::<TrainHandler>().await?;
    handler.delete_train(train_id).await
}

#[tracing::instrument]
pub async fn get_trip_trains(trip_id: Uuid) -> anyhow::Result<Vec<Train>> {
    let handler = DB.try_get::<TrainHandler>().await?;
    handler.get_trip_trains(trip_id).await
}
