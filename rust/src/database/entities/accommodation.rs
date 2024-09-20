use sea_orm::ActiveValue::Set;
use sea_orm::entity::prelude::*;
use uuid::Uuid;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "accommodations")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: Uuid,
    pub trip_id: Uuid,
    pub name: String,
    pub check_in: Option<chrono::DateTime<chrono::Utc>>,
    pub check_out: Option<chrono::DateTime<chrono::Utc>>,
    pub address: Option<String>,
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

impl Related<super::attachment::Entity> for Entity {
    fn to() -> RelationDef {
        super::accommodation_attachment::Relation::Attachment.def()
    }

    fn via() -> Option<RelationDef> {
        Some(super::accommodation_attachment::Relation::Accommodation.def().rev())
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
