pub use weather_sync_job::WeatherSyncJob;
use crate::database::Database;
use crate::handlers::Handler;

mod weather_sync_job;

pub struct BackgroundJobHandler {
    weather_sync_job: WeatherSyncJob,
}

impl Handler for BackgroundJobHandler {
    fn create(db: Database) -> Self {
        Self {
            weather_sync_job: WeatherSyncJob::new(db),
        }
    }
}

impl BackgroundJobHandler {
    pub fn run(&self) -> anyhow::Result<()> {
        self.weather_sync_job.run()
    }
}

pub trait Job {
    fn run(&self) -> anyhow::Result<()>;
}
