use sea_orm::ActiveValue::Set;
use sea_orm::entity::prelude::*;
use uuid::Uuid;
use crate::database::enums::WeatherCondition;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "weather_daily_forecast")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: Uuid,
    pub forecast_id: Uuid,
    pub day: chrono::DateTime<chrono::Utc>,
    pub min_temperature: f64,
    pub max_temperature: f64,
    pub morning_temperature: f64,
    pub day_temperature: f64,
    pub evening_temperature: f64,
    pub night_temperature: f64,
    pub condition: WeatherCondition,
    /// mm
    pub precipitation_amount: f64,
    pub precipitation_probability: f64,
    pub wind_speed: f64,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::weather_forecast::Entity",
        from = "Column::ForecastId",
        to = "super::weather_forecast::Column::Id"
    )]
    Forecast
}

impl Related<super::weather_forecast::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Forecast.def()
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
