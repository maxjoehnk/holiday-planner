use sea_orm::ActiveValue::Set;
use sea_orm::entity::prelude::*;
use uuid::Uuid;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "trains")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: Uuid,
    pub trip_id: Uuid,
    pub train_number: Option<String>,
    pub departure_station_name: String,
    pub departure_station_city: Option<String>,
    pub departure_station_country: Option<String>,
    pub departure_scheduled_platform: String,
    pub arrival_station_name: String,
    pub arrival_station_city: Option<String>,
    pub arrival_station_country: Option<String>,
    pub arrival_scheduled_platform: String,
    pub scheduled_departure_time: DateTimeUtc,
    pub scheduled_arrival_time: DateTimeUtc,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::trip::Entity",
        from = "Column::TripId",
        to = "super::trip::Column::Id"
    )]
    Trip
}

impl Related<super::trip::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Trip.def()
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
