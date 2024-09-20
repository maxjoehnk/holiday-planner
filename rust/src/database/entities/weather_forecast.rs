use sea_orm::ActiveValue::Set;
use sea_orm::entity::prelude::*;
use uuid::Uuid;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "weather_forecast")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: Uuid,
    pub location_id: Uuid,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::location::Entity",
        from = "Column::LocationId",
        to = "super::location::Column::Id"
    )]
    Location,
    #[sea_orm(
        has_many = "super::weather_daily_forecast::Entity",
    )]
    DailyForecast,
    #[sea_orm(
        has_many = "super::weather_hourly_forecast::Entity",
    )]
    HourlyForecast,
}

impl Related<super::location::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Location.def()
    }
}

impl Related<super::weather_daily_forecast::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::DailyForecast.def()
    }
}

impl Related<super::weather_hourly_forecast::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::HourlyForecast.def()
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
