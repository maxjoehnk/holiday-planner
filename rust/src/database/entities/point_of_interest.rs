use sea_orm::ActiveValue::Set;
use sea_orm::entity::prelude::*;
use uuid::Uuid;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "points_of_interest")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: Uuid,
    pub trip_id: Uuid,
    pub name: String,
    pub address: String,
    pub website: Option<String>,
    pub opening_hours: Option<String>,
    pub price: Option<String>,
    pub phone_number: Option<String>,
    pub note: Option<String>,
    // TODO: see how this can be moved into a struct with sea_orm
    pub coordinates_latitude: Option<f64>,
    pub coordinates_longitude: Option<f64>,
    pub trip_day_id: Option<Uuid>,
    pub day_order: Option<i32>,
    pub scheduled_at: Option<DateTimeUtc>,
    pub updated_at: DateTimeUtc,
    pub deleted_at: Option<DateTimeUtc>,
    pub last_modified_by: Option<String>,
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
            ..ActiveModelTrait::default()
        }
    }
}
