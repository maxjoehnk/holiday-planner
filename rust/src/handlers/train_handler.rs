use sea_orm::ActiveValue::Set;
use sea_orm::IntoActiveModel;
use uuid::Uuid;
use crate::commands::{AddTrain, UpdateTrain, ParseSharedTrainData, ParseTrainData};
use crate::database::{Database, entities, repositories};
use crate::handlers::Handler;
use crate::models::transits::{Train, ParsedTrainJourney, ParsedTrainSegment};

pub struct TrainHandler {
    db: Database,
}

impl Handler for TrainHandler {
    fn create(db: Database) -> Self {
        Self {
            db,
        }
    }
}

impl TrainHandler {
    pub async fn add_train(&self, command: AddTrain) -> anyhow::Result<()> {
        tracing::debug!("Adding train to trip {}", command.trip_id);
        
        let train = entities::train::ActiveModel {
            id: Set(Uuid::new_v4()),
            trip_id: Set(command.trip_id),
            train_number: Set(command.train_number),
            departure_station_name: Set(command.departure_station_name),
            departure_station_city: Set(command.departure_station_city),
            departure_station_country: Set(command.departure_station_country),
            departure_scheduled_platform: Set(command.departure_scheduled_platform),
            arrival_station_name: Set(command.arrival_station_name),
            arrival_station_city: Set(command.arrival_station_city),
            arrival_station_country: Set(command.arrival_station_country),
            arrival_scheduled_platform: Set(command.arrival_scheduled_platform),
            scheduled_departure_time: Set(command.scheduled_departure_time),
            scheduled_arrival_time: Set(command.scheduled_arrival_time),
        };
        
        repositories::transits::insert_train(&self.db, train).await?;

        Ok(())
    }
    
    pub async fn get_trip_trains(&self, trip_id: Uuid) -> anyhow::Result<Vec<Train>> {
        let trains = repositories::transits::find_all_trains_by_trip(&self.db, trip_id).await?;
        let trains = trains.into_iter().map(|t| Train {
            id: t.id,
            train_number: t.train_number,
            departure: crate::models::transits::TrainStation {
                name: t.departure_station_name,
                scheduled_platform: t.departure_scheduled_platform,
                actual_platform: None,
                city: t.departure_station_city,
                country: t.departure_station_country,
            },
            arrival: crate::models::transits::TrainStation {
                name: t.arrival_station_name,
                scheduled_platform: t.arrival_scheduled_platform,
                actual_platform: None,
                city: t.arrival_station_city,
                country: t.arrival_station_country,
            },
            scheduled_departure_time: t.scheduled_departure_time,
            scheduled_arrival_time: t.scheduled_arrival_time,
            estimated_departure_time: None, // Not used for now as per requirements
            estimated_arrival_time: None, // Not used for now as per requirements
        }).collect();
        
        Ok(trains)
    }

    pub async fn update_train(&self, command: UpdateTrain) -> anyhow::Result<()> {
        let Some(train) = repositories::transits::find_train_by_id(&self.db, command.id).await? else {
            anyhow::bail!("Unknown train");
        };
        let mut train = train.into_active_model();
        train.train_number.set_if_not_equals(command.train_number);
        train.departure_station_name.set_if_not_equals(command.departure_station_name);
        train.departure_station_city.set_if_not_equals(command.departure_station_city);
        train.departure_station_country.set_if_not_equals(command.departure_station_country);
        train.departure_scheduled_platform.set_if_not_equals(command.departure_scheduled_platform);
        train.arrival_station_name.set_if_not_equals(command.arrival_station_name);
        train.arrival_station_city.set_if_not_equals(command.arrival_station_city);
        train.arrival_station_country.set_if_not_equals(command.arrival_station_country);
        train.arrival_scheduled_platform.set_if_not_equals(command.arrival_scheduled_platform);
        train.scheduled_departure_time.set_if_not_equals(command.scheduled_departure_time);
        train.scheduled_arrival_time.set_if_not_equals(command.scheduled_arrival_time);

        repositories::transits::update_train(&self.db, train).await?;

        Ok(())
    }

    pub async fn delete_train(&self, train_id: Uuid) -> anyhow::Result<()> {
        repositories::transits::delete_train_by_id(&self.db, train_id).await?;

        Ok(())
    }

    pub async fn parse_shared_train_data(&self, command: ParseSharedTrainData) -> anyhow::Result<()> {
        tracing::debug!("Parsing shared train data for trip {}", command.trip_id);
        
        // Parse the shared train information
        let parsed_journey = crate::parsers::train_parser::parse_db_train_info(&command.shared_text)?;
        
        // Store the count before moving the segments
        let segments_count = parsed_journey.segments.len();
        
        // Create AddTrain commands for each segment and add them
        for segment in parsed_journey.segments {
            let add_train_command = AddTrain {
                trip_id: command.trip_id,
                train_number: segment.train_number,
                departure_station_name: segment.departure_station_name,
                departure_station_city: segment.departure_station_city,
                departure_station_country: segment.departure_station_country,
                departure_scheduled_platform: segment.departure_scheduled_platform.unwrap_or_default(),
                arrival_station_name: segment.arrival_station_name,
                arrival_station_city: segment.arrival_station_city,
                arrival_station_country: segment.arrival_station_country,
                arrival_scheduled_platform: segment.arrival_scheduled_platform.unwrap_or_default(),
                scheduled_departure_time: segment.scheduled_departure_time.to_utc(),
                scheduled_arrival_time: segment.scheduled_arrival_time.to_utc(),
            };
            
            self.add_train(add_train_command).await?;
        }
        
        tracing::info!("Successfully added {} train segments to trip {}", 
                      segments_count, command.trip_id);
        
        Ok(())
    }

    pub async fn parse_train_data(&self, command: ParseTrainData) -> anyhow::Result<ParsedTrainJourney> {
        tracing::debug!("Parsing train data without saving");
        
        // Parse the shared train information
        let parsed_journey = crate::parsers::train_parser::parse_db_train_info(&command.shared_text)?;
        
        // Convert from parser types to API types
        let segments: Vec<ParsedTrainSegment> = parsed_journey.segments.into_iter().map(|segment| {
            ParsedTrainSegment {
                train_number: segment.train_number,
                departure_station_name: segment.departure_station_name,
                departure_station_city: segment.departure_station_city,
                departure_station_country: segment.departure_station_country,
                departure_scheduled_platform: segment.departure_scheduled_platform,
                arrival_station_name: segment.arrival_station_name,
                arrival_station_city: segment.arrival_station_city,
                arrival_station_country: segment.arrival_station_country,
                arrival_scheduled_platform: segment.arrival_scheduled_platform,
                scheduled_departure_time: segment.scheduled_departure_time.to_utc(),
                scheduled_arrival_time: segment.scheduled_arrival_time.to_utc(),
            }
        }).collect();
        
        Ok(ParsedTrainJourney {
            segments,
            journey_url: parsed_journey.journey_url,
        })
    }
}
