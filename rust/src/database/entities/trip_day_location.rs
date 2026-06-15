use sea_orm::entity::prelude::*;
use uuid::Uuid;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "trip_day_locations")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub trip_day_id: Uuid,
    #[sea_orm(primary_key, auto_increment = false)]
    pub location_id: Uuid,
    pub is_primary: bool,
    pub display_order: i32,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::trip_day::Entity",
        from = "Column::TripDayId",
        to = "super::trip_day::Column::Id"
    )]
    TripDay,
    #[sea_orm(
        belongs_to = "super::location::Entity",
        from = "Column::LocationId",
        to = "super::location::Column::Id"
    )]
    Location,
}

impl Related<super::trip_day::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::TripDay.def()
    }
}

impl Related<super::location::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Location.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
