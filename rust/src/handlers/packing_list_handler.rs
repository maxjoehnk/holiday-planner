use sea_orm::ActiveValue::Set;
use sea_orm::IntoActiveModel;
use uuid::Uuid;
use crate::database::{Database, repositories, entities, enums};
use crate::models::*;
use crate::commands::*;
use crate::handlers::Handler;

pub struct PackingListHandler {
    db: Database,
}

impl Handler for PackingListHandler {
    fn create(db: Database) -> Self {
        Self {
            db,
        }
    }
}

impl PackingListHandler {
    pub async fn get_packing_list(&self) -> anyhow::Result<Vec<PackingListEntry>> {
        let packing_list_entries = repositories::packing_list_entries::find_all(&self.db).await?;
        let packing_list_entries = packing_list_entries
            .into_iter()
            .map(PackingListEntry::from)
            .collect();

        Ok(packing_list_entries)
    }

    pub async fn add_packing_list_entry(&self, command: AddPackingListEntry) -> anyhow::Result<()> {
        let entry_id = Uuid::new_v4();
        let entry = entities::packing_list_entry::ActiveModel {
            id: Set(entry_id),
            name: Set(command.name),
            description: Set(command.description),
            quantity_per_day: Set(command.quantity.per_day.map(|quantity| quantity as i64)),
            quantity_per_night: Set(command.quantity.per_night.map(|quantity| quantity as i64)),
            quantity_fixed: Set(command.quantity.fixed.map(|quantity| quantity as i64)),
            group_id: Set(None),
        };
        repositories::packing_list_entries::insert(&self.db, entry).await?;

        self.add_packing_list_conditions(entry_id, command.conditions).await?;

        Ok(())
    }

    async fn add_packing_list_conditions(&self, entry_id: Uuid, conditions: Vec<PackingListEntryCondition>) -> anyhow::Result<()> {
        for condition in conditions {
            match condition {
                PackingListEntryCondition::MinTripDuration {
                    length
                } => {
                    let condition = entities::packing_list_condition::ActiveModel {
                        packing_list_entry_id: Set(entry_id),
                        min_trip_duration: Set(Some(length as i64)),
                        ..Default::default()
                    };
                    repositories::packing_list_conditions::insert(&self.db, entry_id, condition).await?;
                }
                PackingListEntryCondition::MaxTripDuration {
                    length
                } => {
                    let condition = entities::packing_list_condition::ActiveModel {
                        packing_list_entry_id: Set(entry_id),
                        max_trip_duration: Set(Some(length as i64)),
                        ..Default::default()
                    };
                    repositories::packing_list_conditions::insert(&self.db, entry_id, condition).await?;
                }
                PackingListEntryCondition::MinTemperature {
                    temperature
                } => {
                    let condition = entities::packing_list_condition::ActiveModel {
                        packing_list_entry_id: Set(entry_id),
                        min_temperature: Set(Some(temperature)),
                        ..Default::default()
                    };
                    repositories::packing_list_conditions::insert(&self.db, entry_id, condition).await?;
                }
                PackingListEntryCondition::MaxTemperature {
                    temperature
                } => {
                    let condition = entities::packing_list_condition::ActiveModel {
                        packing_list_entry_id: Set(entry_id),
                        max_temperature: Set(Some(temperature)),
                        ..Default::default()
                    };
                    repositories::packing_list_conditions::insert(&self.db, entry_id, condition).await?;
                }
                PackingListEntryCondition::Weather {
                    condition,
                    min_probability
                } => {
                    let condition = entities::packing_list_condition::ActiveModel {
                        packing_list_entry_id: Set(entry_id),
                        weather_min_probability: Set(Some(min_probability)),
                        weather_condition: Set(Some(condition.into())),
                        ..Default::default()
                    };
                    repositories::packing_list_conditions::insert(&self.db, entry_id, condition).await?;
                }
                PackingListEntryCondition::Tag {
                    tag_id
                } => {
                    let condition = entities::packing_list_condition::ActiveModel {
                        packing_list_entry_id: Set(entry_id),
                        tag: Set(Some(tag_id)),
                        ..Default::default()
                    };
                    repositories::packing_list_conditions::insert(&self.db, entry_id, condition).await?;
                }
            }
        }

        Ok(())
    }

    pub async fn update_packing_list_entry(&self, command: UpdatePackingListEntry) -> anyhow::Result<()> {
        let Some(entry) = repositories::packing_list_entries::find_by_id(&self.db, command.id).await? else {
            anyhow::bail!("Unknown packing list entry");
        };
        let mut entry = entry.into_active_model();
        entry.name.set_if_not_equals(command.name);
        entry.description.set_if_not_equals(command.description);
        entry.quantity_fixed.set_if_not_equals(command.quantity.fixed.map(|q| q as i64));
        entry.quantity_per_day.set_if_not_equals(command.quantity.per_day.map(|q| q as i64));
        entry.quantity_per_night.set_if_not_equals(command.quantity.per_night.map(|q| q as i64));

        repositories::packing_list_entries::update(&self.db, entry).await?;

        repositories::packing_list_conditions::delete_by_entry_id(&self.db, command.id).await?;

        self.add_packing_list_conditions(command.id, command.conditions).await?;

        Ok(())
    }

    pub async fn delete_packing_list_entry(&self, command: DeletePackingListEntry) -> anyhow::Result<()> {
        repositories::packing_list_entries::delete_by_id(&self.db, command.id).await?;

        Ok(())
    }
}

impl From<entities::packing_list_entry::Model> for PackingListEntry {
    fn from(entry: entities::packing_list_entry::Model) -> Self {
        PackingListEntry {
            id: entry.id,
            name: entry.name,
            description: entry.description,
            conditions: Default::default(),
            quantity: Quantity {
                per_day: entry.quantity_per_day.map(|quantity| quantity as usize),
                per_night: entry.quantity_per_night.map(|quantity| quantity as usize),
                fixed: entry.quantity_fixed.map(|quantity| quantity as usize),
            },
            category: None,
        }
    }
}

impl From<(entities::packing_list_entry::Model, Vec<entities::packing_list_condition::Model>)> for PackingListEntry {
    fn from((entry, conditions): (entities::packing_list_entry::Model, Vec<entities::packing_list_condition::Model>)) -> Self {
        PackingListEntry {
            conditions: conditions.into_iter().map(PackingListEntryCondition::from).collect(),
            ..PackingListEntry::from(entry)
        }
    }
}

impl From<entities::packing_list_condition::Model> for PackingListEntryCondition {
    fn from(condition: entities::packing_list_condition::Model) -> Self {
        if let Some(min_trip_duration) = condition.min_trip_duration {
            PackingListEntryCondition::MinTripDuration {
                length: min_trip_duration as u32,
            }
        } else if let Some(max_trip_duration) = condition.max_trip_duration {
            PackingListEntryCondition::MaxTripDuration {
                length: max_trip_duration as u32,
            }
        } else if let Some(min_temperature) = condition.min_temperature {
            PackingListEntryCondition::MinTemperature {
                temperature: min_temperature,
            }
        } else if let Some(max_temperature) = condition.max_temperature {
            PackingListEntryCondition::MaxTemperature {
                temperature: max_temperature,
            }
        } else if let Some((weather_min_probability, condition)) = condition.weather_min_probability.zip(condition.weather_condition) {
            PackingListEntryCondition::Weather {
                condition: condition.into(),
                min_probability: weather_min_probability,
            }
        } else if let Some(tag_id) = condition.tag {
            PackingListEntryCondition::Tag {
                tag_id
            }
        } else {
            unreachable!()
        }
    }
}

impl From<enums::WeatherCondition> for WeatherCondition {
    fn from(value: enums::WeatherCondition) -> Self {
        match value {
            enums::WeatherCondition::Sunny => WeatherCondition::Sunny,
            enums::WeatherCondition::Clouds => WeatherCondition::Clouds,
            enums::WeatherCondition::Rain => WeatherCondition::Rain,
            enums::WeatherCondition::Snow => WeatherCondition::Snow,
            enums::WeatherCondition::Thunderstorm => WeatherCondition::Thunderstorm,
        }
    }
}

impl From<WeatherCondition> for enums::WeatherCondition {
    fn from(value: WeatherCondition) -> Self {
        match value {
            WeatherCondition::Sunny => enums::WeatherCondition::Sunny,
            WeatherCondition::Clouds => enums::WeatherCondition::Clouds,
            WeatherCondition::Rain => enums::WeatherCondition::Rain,
            WeatherCondition::Snow => enums::WeatherCondition::Snow,
            WeatherCondition::Thunderstorm => enums::WeatherCondition::Thunderstorm,
        }
    }
}
