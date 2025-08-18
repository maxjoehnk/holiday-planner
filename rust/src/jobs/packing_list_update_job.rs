use std::collections::HashMap;
use sea_orm::ActiveValue::Set;
use sea_orm::{IntoActiveModel, TransactionTrait};
use crate::database::{Database, repositories, entities};
use crate::database::entities::trip::Model as Trip;
use crate::database::entities::{weather_daily_forecast, weather_hourly_forecast};
use crate::jobs::Job;
use crate::models::{PackingListEntry, PackingListEntryCondition, DailyWeatherForecast, WeatherCondition};

pub struct PackingListUpdateJob {
    db: Database,
}

impl PackingListUpdateJob {
    pub fn new(db: Database) -> Self {
        Self {
            db,
        }
    }
}

impl Job for PackingListUpdateJob {
    async fn run(&self) -> anyhow::Result<()> {
        tracing::info!("Running packing list job");
        let packing_list_entries = repositories::packing_list_entries::find_all(&self.db).await?;
        let packing_list_entries = packing_list_entries.into_iter().map(PackingListEntry::from).collect::<Vec<_>>();
        let trips = repositories::trips::find_upcoming(&self.db).await?;
        for trip in trips {
            tracing::debug!("Updating packing list for trip {}", trip.name);
            
            let locations = repositories::locations::find_all_by_trip(&self.db, trip.id).await?;
            let forecasts = repositories::weather_forecasts::load_forecasts_for_locations(&self.db, &locations).await?;
            let daily_forecasts: Vec<DailyWeatherForecast> = forecasts.into_iter()
                .flat_map(|(daily, _)| daily.into_iter().map(DailyWeatherForecast::from))
                .collect();
            
            // Load trip tags for condition matching
            let trip_tags = repositories::tags::find_by_trip_id(&self.db, trip.id).await?;
            let trip_tag_ids: Vec<uuid::Uuid> = trip_tags.into_iter().map(|tag| tag.id).collect();
            
            let packing_entries = repositories::trip_packing_list_entries::find_trip_entries_by_trip(&self.db, trip.id).await?;
            let mut packing_entries = packing_entries.into_iter()
                .map(|entry| (entry.packing_list_entry_id, entry.into_active_model()))
                .collect::<HashMap<_, _>>();
            for packing_list_entry in &packing_list_entries {
                if packing_list_entry.conditions.is_empty() || packing_list_entry.conditions.iter().any(|condition| condition.matches(&trip, &daily_forecasts, &trip_tag_ids)) {
                    let quantity = packing_list_entry.quantity.calculate(trip.start_date, trip.end_date);
                    if let Some(mut model) = packing_entries.remove(&packing_list_entry.id) {
                        model.quantity = Set(quantity.map(|q| q as i64));
                        repositories::trip_packing_list_entries::update(&self.db, trip.id, model).await?;
                    }else {
                        let model = entities::trip_packing_list_entry::ActiveModel {
                            packing_list_entry_id: Set(packing_list_entry.id),
                            trip_id: Set(trip.id),
                            quantity: Set(quantity.map(|q| q as i64)),
                            ..Default::default()
                        };
                        repositories::trip_packing_list_entries::insert(&self.db, model).await?;
                    }
                }
            }
            let entries_to_be_removed = packing_entries.into_iter().map(|(id, _)| id).collect::<Vec<_>>();
            repositories::trip_packing_list_entries::delete_many_by_ids(&self.db, trip.id, entries_to_be_removed).await?;
        }

        tracing::info!("Finished packing list job");

        Ok(())
    }
}

impl PackingListEntryCondition {
    pub(crate) fn matches(&self, trip: &Trip, daily_forecasts: &[DailyWeatherForecast], trip_tag_ids: &[uuid::Uuid]) -> bool {
        match self {
            Self::MinTripDuration { length } => {
                let duration = trip.end_date.signed_duration_since(trip.start_date);
                let days = duration.num_days() as usize;

                (*length as usize) <= days
            }
            Self::MaxTripDuration { length } => {
                let duration = trip.end_date.signed_duration_since(trip.start_date);
                let days = duration.num_days() as usize;

                (*length as usize) > days
            }
            Self::MinTemperature { temperature } => {
                daily_forecasts.iter().any(|forecast| {
                    forecast.day >= trip.start_date && forecast.day <= trip.end_date &&
                    forecast.min_temperature >= *temperature
                })
            }
            Self::MaxTemperature { temperature } => {
                daily_forecasts.iter().any(|forecast| {
                    forecast.day >= trip.start_date && forecast.day <= trip.end_date &&
                    forecast.max_temperature <= *temperature
                })
            }
            Self::Weather { condition, min_probability } => {
                let matching_days = daily_forecasts.iter()
                    .filter(|forecast| {
                        forecast.day >= trip.start_date && forecast.day <= trip.end_date &&
                        forecast.condition == *condition
                    })
                    .count();
                
                let total_days = trip.end_date.signed_duration_since(trip.start_date).num_days().max(1) as usize;
                
                let probability = matching_days as f64 / total_days as f64;
                probability >= *min_probability
            }
            Self::Tag { tag_id } => {
                trip_tag_ids.contains(tag_id)
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::{DateTime, Utc, TimeZone};
    use crate::models::{WeatherCondition, DailyWeatherForecast};

    fn create_test_trip(start_date: DateTime<Utc>, end_date: DateTime<Utc>) -> Trip {
        Trip {
            id: uuid::Uuid::new_v4(),
            name: "Test Trip".to_string(),
            start_date,
            end_date,
            header_image: None,
        }
    }

    fn create_test_forecast(day: DateTime<Utc>, min_temp: f64, max_temp: f64, condition: WeatherCondition) -> DailyWeatherForecast {
        DailyWeatherForecast {
            day,
            min_temperature: min_temp,
            max_temperature: max_temp,
            morning_temperature: (min_temp + max_temp) / 2.0,
            day_temperature: max_temp - 2.0,
            evening_temperature: (min_temp + max_temp) / 2.0,
            night_temperature: min_temp + 1.0,
            condition,
            precipitation_amount: 0.0,
            precipitation_probability: 0.0,
            wind_speed: 0.0,
        }
    }

    #[test]
    fn test_min_trip_duration_matches() {
        let start_date = Utc.with_ymd_and_hms(2023, 7, 1, 0, 0, 0).unwrap();
        let end_date = Utc.with_ymd_and_hms(2023, 7, 5, 0, 0, 0).unwrap(); // 4 days
        let trip = create_test_trip(start_date, end_date);
        let condition = PackingListEntryCondition::MinTripDuration { length: 3 };
        let forecasts = vec![];

        let result = condition.matches(&trip, &forecasts, &[]);

        assert!(result, "Trip duration of 4 days should match minimum duration of 3 days");
    }

    #[test]
    fn test_min_trip_duration_does_not_match() {
        let start_date = Utc.with_ymd_and_hms(2023, 7, 1, 0, 0, 0).unwrap();
        let end_date = Utc.with_ymd_and_hms(2023, 7, 3, 0, 0, 0).unwrap(); // 2 days
        let trip = create_test_trip(start_date, end_date);
        let condition = PackingListEntryCondition::MinTripDuration { length: 5 };
        let forecasts = vec![];

        let result = condition.matches(&trip, &forecasts, &[]);

        assert!(!result, "Trip duration of 2 days should not match minimum duration of 5 days");
    }

    #[test]
    fn test_max_trip_duration_matches() {
        let start_date = Utc.with_ymd_and_hms(2023, 7, 1, 0, 0, 0).unwrap();
        let end_date = Utc.with_ymd_and_hms(2023, 7, 3, 0, 0, 0).unwrap(); // 2 days
        let trip = create_test_trip(start_date, end_date);
        let condition = PackingListEntryCondition::MaxTripDuration { length: 5 };
        let forecasts = vec![];

        let result = condition.matches(&trip, &forecasts, &[]);

        assert!(result, "Trip duration of 2 days should match maximum duration of 5 days");
    }

    #[test]
    fn test_max_trip_duration_does_not_match() {
        let start_date = Utc.with_ymd_and_hms(2023, 7, 1, 0, 0, 0).unwrap();
        let end_date = Utc.with_ymd_and_hms(2023, 7, 8, 0, 0, 0).unwrap(); // 7 days
        let trip = create_test_trip(start_date, end_date);
        let condition = PackingListEntryCondition::MaxTripDuration { length: 5 };
        let forecasts = vec![];

        let result = condition.matches(&trip, &forecasts, &[]);

        assert!(!result, "Trip duration of 7 days should not match maximum duration of 5 days");
    }

    #[test]
    fn test_min_temperature_matches() {
        let start_date = Utc.with_ymd_and_hms(2023, 7, 1, 0, 0, 0).unwrap();
        let end_date = Utc.with_ymd_and_hms(2023, 7, 3, 0, 0, 0).unwrap();
        let trip = create_test_trip(start_date, end_date);
        let condition = PackingListEntryCondition::MinTemperature { temperature: 20.0 };
        let forecasts = vec![
            create_test_forecast(Utc.with_ymd_and_hms(2023, 7, 1, 0, 0, 0).unwrap(), 18.0, 25.0, WeatherCondition::Sunny),
            create_test_forecast(Utc.with_ymd_and_hms(2023, 7, 2, 0, 0, 0).unwrap(), 22.0, 28.0, WeatherCondition::Sunny),
        ];

        let result = condition.matches(&trip, &forecasts, &[]);

        assert!(result, "Should match when at least one day has min temperature >= 20.0");
    }

    #[test]
    fn test_min_temperature_does_not_match() {
        let start_date = Utc.with_ymd_and_hms(2023, 7, 1, 0, 0, 0).unwrap();
        let end_date = Utc.with_ymd_and_hms(2023, 7, 3, 0, 0, 0).unwrap();
        let trip = create_test_trip(start_date, end_date);
        let condition = PackingListEntryCondition::MinTemperature { temperature: 25.0 };
        let forecasts = vec![
            create_test_forecast(Utc.with_ymd_and_hms(2023, 7, 1, 0, 0, 0).unwrap(), 18.0, 22.0, WeatherCondition::Sunny),
            create_test_forecast(Utc.with_ymd_and_hms(2023, 7, 2, 0, 0, 0).unwrap(), 20.0, 24.0, WeatherCondition::Sunny),
        ];

        let result = condition.matches(&trip, &forecasts, &[]);

        assert!(!result, "Should not match when no day has min temperature >= 25.0");
    }

    #[test]
    fn test_max_temperature_matches() {
        let start_date = Utc.with_ymd_and_hms(2023, 7, 1, 0, 0, 0).unwrap();
        let end_date = Utc.with_ymd_and_hms(2023, 7, 3, 0, 0, 0).unwrap();
        let trip = create_test_trip(start_date, end_date);
        let condition = PackingListEntryCondition::MaxTemperature { temperature: 25.0 };
        let forecasts = vec![
            create_test_forecast(Utc.with_ymd_and_hms(2023, 7, 1, 0, 0, 0).unwrap(), 18.0, 30.0, WeatherCondition::Sunny),
            create_test_forecast(Utc.with_ymd_and_hms(2023, 7, 2, 0, 0, 0).unwrap(), 15.0, 22.0, WeatherCondition::Clouds),
        ];

        let result = condition.matches(&trip, &forecasts, &[]);

        assert!(result, "Should match when at least one day has max temperature <= 25.0");
    }

    #[test]
    fn test_max_temperature_does_not_match() {
        let start_date = Utc.with_ymd_and_hms(2023, 7, 1, 0, 0, 0).unwrap();
        let end_date = Utc.with_ymd_and_hms(2023, 7, 3, 0, 0, 0).unwrap();
        let trip = create_test_trip(start_date, end_date);
        let condition = PackingListEntryCondition::MaxTemperature { temperature: 20.0 };
        let forecasts = vec![
            create_test_forecast(Utc.with_ymd_and_hms(2023, 7, 1, 0, 0, 0).unwrap(), 18.0, 25.0, WeatherCondition::Sunny),
            create_test_forecast(Utc.with_ymd_and_hms(2023, 7, 2, 0, 0, 0).unwrap(), 20.0, 28.0, WeatherCondition::Sunny),
        ];

        let result = condition.matches(&trip, &forecasts, &[]);

        assert!(!result, "Should not match when no day has max temperature <= 20.0");
    }

    #[test]
    fn test_weather_condition_matches() {
        let start_date = Utc.with_ymd_and_hms(2023, 7, 1, 0, 0, 0).unwrap();
        let end_date = Utc.with_ymd_and_hms(2023, 7, 5, 0, 0, 0).unwrap(); // 4 days
        let trip = create_test_trip(start_date, end_date);
        let condition = PackingListEntryCondition::Weather { 
            condition: WeatherCondition::Rain, 
            min_probability: 0.5 // 50%
        };
        let forecasts = vec![
            create_test_forecast(Utc.with_ymd_and_hms(2023, 7, 1, 0, 0, 0).unwrap(), 18.0, 25.0, WeatherCondition::Rain),
            create_test_forecast(Utc.with_ymd_and_hms(2023, 7, 2, 0, 0, 0).unwrap(), 20.0, 28.0, WeatherCondition::Rain),
            create_test_forecast(Utc.with_ymd_and_hms(2023, 7, 3, 0, 0, 0).unwrap(), 22.0, 30.0, WeatherCondition::Sunny),
            create_test_forecast(Utc.with_ymd_and_hms(2023, 7, 4, 0, 0, 0).unwrap(), 19.0, 26.0, WeatherCondition::Sunny),
        ];

        let result = condition.matches(&trip, &forecasts, &[]);

        assert!(result, "Should match when 2 out of 4 days (50%) have rain condition");
    }

    #[test]
    fn test_weather_condition_does_not_match() {
        let start_date = Utc.with_ymd_and_hms(2023, 7, 1, 0, 0, 0).unwrap();
        let end_date = Utc.with_ymd_and_hms(2023, 7, 5, 0, 0, 0).unwrap(); // 4 days
        let trip = create_test_trip(start_date, end_date);
        let condition = PackingListEntryCondition::Weather { 
            condition: WeatherCondition::Rain, 
            min_probability: 0.75 // 75%
        };
        let forecasts = vec![
            create_test_forecast(Utc.with_ymd_and_hms(2023, 7, 1, 0, 0, 0).unwrap(), 18.0, 25.0, WeatherCondition::Rain),
            create_test_forecast(Utc.with_ymd_and_hms(2023, 7, 2, 0, 0, 0).unwrap(), 20.0, 28.0, WeatherCondition::Sunny),
            create_test_forecast(Utc.with_ymd_and_hms(2023, 7, 3, 0, 0, 0).unwrap(), 22.0, 30.0, WeatherCondition::Sunny),
            create_test_forecast(Utc.with_ymd_and_hms(2023, 7, 4, 0, 0, 0).unwrap(), 19.0, 26.0, WeatherCondition::Sunny),
        ];

        let result = condition.matches(&trip, &forecasts, &[]);

        assert!(!result, "Should not match when only 1 out of 4 days (25%) have rain condition, but 75% is required");
    }

    #[test]
    fn test_forecasts_outside_trip_dates_ignored() {
        let start_date = Utc.with_ymd_and_hms(2023, 7, 2, 0, 0, 0).unwrap();
        let end_date = Utc.with_ymd_and_hms(2023, 7, 3, 0, 0, 0).unwrap();
        let trip = create_test_trip(start_date, end_date);
        let condition = PackingListEntryCondition::MinTemperature { temperature: 25.0 };
        let forecasts = vec![
            // Before trip
            create_test_forecast(Utc.with_ymd_and_hms(2023, 7, 1, 0, 0, 0).unwrap(), 30.0, 35.0, WeatherCondition::Sunny),
            // During trip
            create_test_forecast(Utc.with_ymd_and_hms(2023, 7, 2, 0, 0, 0).unwrap(), 20.0, 24.0, WeatherCondition::Sunny),
            // After trip
            create_test_forecast(Utc.with_ymd_and_hms(2023, 7, 4, 0, 0, 0).unwrap(), 28.0, 32.0, WeatherCondition::Sunny),
        ];

        let result = condition.matches(&trip, &forecasts, &[]);

        assert!(!result, "Should only consider forecasts within trip dates, ignoring high temperatures outside the trip");
    }

    #[test]
    fn test_tag_condition_matches() {
        let start_date = Utc.with_ymd_and_hms(2023, 7, 1, 0, 0, 0).unwrap();
        let end_date = Utc.with_ymd_and_hms(2023, 7, 3, 0, 0, 0).unwrap();
        let trip = create_test_trip(start_date, end_date);
        let tag_id = uuid::Uuid::new_v4();
        let condition = PackingListEntryCondition::Tag { tag_id };
        let forecasts = vec![];
        let trip_tags = vec![tag_id];

        let result = condition.matches(&trip, &forecasts, &trip_tags);

        assert!(result, "Should match when trip has the required tag");
    }

    #[test]
    fn test_tag_condition_does_not_match() {
        let start_date = Utc.with_ymd_and_hms(2023, 7, 1, 0, 0, 0).unwrap();
        let end_date = Utc.with_ymd_and_hms(2023, 7, 3, 0, 0, 0).unwrap();
        let trip = create_test_trip(start_date, end_date);
        let tag_id = uuid::Uuid::new_v4();
        let other_tag_id = uuid::Uuid::new_v4();
        let condition = PackingListEntryCondition::Tag { tag_id };
        let forecasts = vec![];
        let trip_tags = vec![other_tag_id];

        let result = condition.matches(&trip, &forecasts, &trip_tags);

        assert!(!result, "Should not match when trip does not have the required tag");
    }

    #[test]
    fn test_tag_condition_empty_tags() {
        let start_date = Utc.with_ymd_and_hms(2023, 7, 1, 0, 0, 0).unwrap();
        let end_date = Utc.with_ymd_and_hms(2023, 7, 3, 0, 0, 0).unwrap();
        let trip = create_test_trip(start_date, end_date);
        let tag_id = uuid::Uuid::new_v4();
        let condition = PackingListEntryCondition::Tag { tag_id };
        let forecasts = vec![];
        let trip_tags = vec![];

        let result = condition.matches(&trip, &forecasts, &trip_tags);

        assert!(!result, "Should not match when trip has no tags");
    }
}
