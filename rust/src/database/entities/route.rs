use sea_orm::ActiveValue::Set;
use sea_orm::entity::prelude::*;
use uuid::Uuid;

#[derive(Clone, Debug, PartialEq, Eq, DeriveActiveEnum, EnumIter, serde::Serialize, serde::Deserialize)]
#[sea_orm(rs_type = "String", db_type = "Text")]
pub enum RouteProvider {
    #[sea_orm(string_value = "komoot")]
    Komoot,
}

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "routes")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: Uuid,
    pub trip_id: Uuid,
    pub provider: RouteProvider,
    pub provider_route_id: String,
    pub name: String,
    pub sport: Option<String>,
    pub distance_meters: f64,
    pub duration_seconds: i64,
    pub elevation_up_meters: Option<f64>,
    pub elevation_down_meters: Option<f64>,
    pub start_latitude: f64,
    pub start_longitude: f64,
    pub polyline: String,
    pub note: Option<String>,
    pub external_url: String,
    pub trip_day_id: Option<Uuid>,
    pub day_order: Option<i32>,
    pub scheduled_at: Option<DateTimeUtc>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::trip::Entity",
        from = "Column::TripId",
        to = "super::trip::Column::Id"
    )]
    Trip,
    #[sea_orm(
        belongs_to = "super::trip_day::Entity",
        from = "Column::TripDayId",
        to = "super::trip_day::Column::Id"
    )]
    TripDay,
}

impl Related<super::trip::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Trip.def()
    }
}

impl Related<super::trip_day::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::TripDay.def()
    }
}

impl ActiveModelBehavior for ActiveModel {
    fn new() -> Self {
        Self {
            id: Set(Uuid::new_v4()),
            provider: Set(RouteProvider::Komoot),
            ..ActiveModelTrait::default()
        }
    }
}
