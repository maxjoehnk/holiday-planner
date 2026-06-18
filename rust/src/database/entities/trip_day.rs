use sea_orm::ActiveValue::Set;
use sea_orm::entity::prelude::*;
use uuid::Uuid;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "trip_days")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: Uuid,
    pub trip_id: Uuid,
    pub date: chrono::NaiveDate,
    pub title: Option<String>,
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
    #[sea_orm(has_many = "super::point_of_interest::Entity")]
    PointOfInterest,
    #[sea_orm(has_many = "super::route::Entity")]
    Route,
}

impl Related<super::trip::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Trip.def()
    }
}

impl Related<super::point_of_interest::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::PointOfInterest.def()
    }
}

impl Related<super::route::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Route.def()
    }
}

impl Related<super::location::Entity> for Entity {
    fn to() -> RelationDef {
        super::trip_day_location::Relation::Location.def()
    }

    fn via() -> Option<RelationDef> {
        Some(super::trip_day_location::Relation::TripDay.def().rev())
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
