use sea_orm::ActiveValue::Set;
use sea_orm::entity::prelude::*;
use sea_orm::LinkDef;
use uuid::Uuid;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "locations")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: Uuid,
    pub trip_id: Uuid,
    pub coordinates_latitude: f64,
    pub coordinates_longitude: f64,
    pub city: String,
    pub country: String,
    pub is_coastal: bool,
    pub tidal_information_last_updated: Option<DateTimeUtc>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::trip::Entity",
        from = "Column::TripId",
        to = "super::trip::Column::Id"
    )]
    Trip,
}

impl Related<super::trip::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Trip.def()
    }
}

impl Related<super::weather_forecast::Entity> for Entity {
    fn to() -> RelationDef {
        super::weather_forecast::Relation::Location.def().rev()
    }
}

impl Related<super::attachment::Entity> for Entity {
    fn to() -> RelationDef {
        super::location_attachment::Relation::Attachment.def()
    }

    fn via() -> Option<RelationDef> {
        Some(super::location_attachment::Relation::Location.def().rev())
    }
}

impl Related<super::tidal_information::Entity> for Entity {
    fn to() -> RelationDef {
        super::tidal_information::Relation::Location.def().rev()
    }
}

pub struct LocationHourlyForecast;

impl Linked for LocationHourlyForecast {
    type FromEntity = Entity;
    type ToEntity = super::weather_hourly_forecast::Entity;

    fn link(&self) -> Vec<LinkDef> {
        vec![
            super::weather_forecast::Relation::Location.def().rev(),
            super::weather_forecast::Relation::HourlyForecast.def(),
        ]
    }
}

pub struct LocationDailyForecast;

impl Linked for LocationDailyForecast {
    type FromEntity = Entity;
    type ToEntity = super::weather_daily_forecast::Entity;

    fn link(&self) -> Vec<LinkDef> {
        vec![
            super::weather_forecast::Relation::Location.def().rev(),
            super::weather_forecast::Relation::DailyForecast.def(),
        ]
    }
}

impl ActiveModelBehavior for ActiveModel {
    fn new() -> Self {
        Self {
            id: Set(Uuid::new_v4()),
            is_coastal: Set(false),
            ..ActiveModelTrait::default()
        }
    }
}
