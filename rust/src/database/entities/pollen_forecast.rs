use sea_orm::ActiveValue::Set;
use sea_orm::entity::prelude::*;
use uuid::Uuid;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "pollen_forecast")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: Uuid,
    pub location_id: Option<Uuid>,
    pub accommodation_id: Option<Uuid>,
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
        belongs_to = "super::accommodation::Entity",
        from = "Column::AccommodationId",
        to = "super::accommodation::Column::Id"
    )]
    Accommodation,
    #[sea_orm(
        has_many = "super::pollen_daily_forecast::Entity",
    )]
    DailyForecast,
}

impl Related<super::location::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Location.def()
    }
}

impl Related<super::accommodation::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Accommodation.def()
    }
}

impl Related<super::pollen_daily_forecast::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::DailyForecast.def()
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
