use sea_orm::ActiveValue::Set;
use sea_orm::entity::prelude::*;
use uuid::Uuid;

#[derive(Clone, Debug, PartialEq, DeriveActiveEnum, EnumIter, serde::Serialize, serde::Deserialize)]
#[sea_orm(rs_type = "String", db_type = "Text")]
pub enum ReservationCategory {
    #[sea_orm(string_value = "restaurant")]
    Restaurant,
    #[sea_orm(string_value = "activity")]
    Activity,
}

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "reservations")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: Uuid,
    pub trip_id: Uuid,
    pub title: String,
    pub address: Option<String>,
    pub start_date: DateTimeUtc,
    pub end_date: Option<DateTimeUtc>,
    pub link: Option<String>,
    pub booking_number: Option<String>,
    pub category: ReservationCategory,
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
            category: Set(ReservationCategory::Restaurant),
            ..ActiveModelTrait::default()
        }
    }
}
