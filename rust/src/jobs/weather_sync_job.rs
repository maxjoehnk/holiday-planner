use crate::database::Database;
use crate::jobs::Job;
use crate::third_party::openweathermap;

pub struct WeatherSyncJob {
    db: Database,
}

impl WeatherSyncJob {
    pub fn new(db: Database) -> Self {
        Self {
            db,
        }
    }
}

impl Job for WeatherSyncJob {
    fn run(&self) -> anyhow::Result<()> {
        tracing::info!("Running weather sync job");
        for trip in self.db.trip_tree().iter() {
            let (_, trip) = trip?;
            tracing::debug!("Fetching forecasts for trip {}", trip.id);
            let mut locations = trip.locations;
            for location in &mut locations {
                tracing::debug!("Fetching forecast for location {} - {}", location.city, location.country);
                let weather = openweathermap::get_forecast(&location.coordinates)?;
                location.forecast = Some(weather.into());
            }
            self.db.trip_tree().update_and_fetch(&trip.id, |trip| {
                let mut trip = trip?;
                trip.locations = locations.clone();

                Some(trip)
            })?;
        }
        tracing::info!("Finished weather sync job");

        Ok(())
    }
}
