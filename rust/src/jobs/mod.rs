pub use weather_sync_job::WeatherSyncJob;
pub use tidal_sync_job::TidalSyncJob;
use crate::database::Database;
use crate::handlers::Handler;
pub use crate::jobs::packing_list_update_job::PackingListUpdateJob;

mod weather_sync_job;
mod packing_list_update_job;
mod tidal_sync_job;

pub struct BackgroundJobHandler {
    weather_sync_job: WeatherSyncJob,
    packing_list_update_job: PackingListUpdateJob,
    tidal_sync_job: TidalSyncJob,
}

impl Handler for BackgroundJobHandler {
    fn create(db: Database) -> Self {
        Self {
            weather_sync_job: WeatherSyncJob::new(db.clone()),
            packing_list_update_job: PackingListUpdateJob::new(db.clone()),
            tidal_sync_job: TidalSyncJob::new(db),
        }
    }
}

impl BackgroundJobHandler {
    pub async fn run(&self) -> anyhow::Result<()> {
        if let Err(err) = self.weather_sync_job.run().await {
            tracing::error!("Failed to run weather sync job: {err:?}");
        }
        if let Err(err) = self.packing_list_update_job.run().await {
            tracing::error!("Failed to run packing list update job: {err:?}");
        }
        if let Err(err) = self.tidal_sync_job.run().await {
            tracing::error!("Failed to run tidal sync job: {err:?}");
        }
        
        Ok(())
    }
}

pub trait Job {
    async fn run(&self) -> anyhow::Result<()>;
}
