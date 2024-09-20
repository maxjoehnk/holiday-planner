use sea_orm::ActiveValue::Set;
use sea_orm::entity::prelude::*;
use uuid::Uuid;
use crate::database::enums::WeatherCondition;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "packing_list_conditions")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: Uuid,
    pub packing_list_entry_id: Uuid,
    pub min_trip_duration: Option<i64>,
    pub max_trip_duration: Option<i64>,
    pub min_temperature: Option<f64>,
    pub max_temperature: Option<f64>,
    pub weather_min_probability: Option<f64>,
    pub weather_condition: Option<WeatherCondition>,
    pub tag: Option<Uuid>,

}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::packing_list_entry::Entity",
        from = "Column::PackingListEntryId",
        to = "super::packing_list_entry::Column::Id"
    )]
    PackingListEntry,
    #[sea_orm(
        belongs_to = "super::tag::Entity",
        from = "Column::Tag",
        to = "super::tag::Column::Id"
    )]
    Tag,
}

impl Related<super::tag::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Tag.def()
    }
}

impl Related<super::packing_list_entry::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::PackingListEntry.def()
    }
}

impl ActiveModelBehavior for ActiveModel {
    fn new() -> Self {
        Self {
            id: Set(Uuid::new_v4()),
            ..ActiveModelTrait::default()
        }
    }
}
