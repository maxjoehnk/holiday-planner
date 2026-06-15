use sea_orm::ActiveValue::Set;
use sea_orm::entity::prelude::*;
use uuid::Uuid;
use crate::database::enums::PollenType;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "pollen_daily_forecast")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: Uuid,
    pub forecast_id: Uuid,
    pub day: chrono::DateTime<chrono::Utc>,
    pub pollen_type: PollenType,
    pub index_value: i32,
    pub category: Option<String>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::pollen_forecast::Entity",
        from = "Column::ForecastId",
        to = "super::pollen_forecast::Column::Id"
    )]
    Forecast,
}

impl Related<super::pollen_forecast::Entity> for Entity {
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
