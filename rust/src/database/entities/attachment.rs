use sea_orm::ActiveValue::Set;
use sea_orm::entity::prelude::*;
use uuid::Uuid;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "attachments")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: Uuid,
    pub name: String,
    pub trip_id: Uuid,
    pub data: Vec<u8>,
    pub file_name: String,
    pub content_type: String,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::trip::Entity",
        from = "Column::TripId",
        to = "super::trip::Column::Id"
    )]
    Trip,
    #[sea_orm(has_many = "super::accommodation_attachment::Entity")]
    AccommodationAttachment
}

impl Related<super::trip::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Trip.def()
    }
}

impl Related<super::accommodation::Entity> for Entity {
    fn to() -> RelationDef {
        super::accommodation_attachment::Relation::Accommodation.def()
    }

    fn via() -> Option<RelationDef> {
        Some(super::accommodation_attachment::Relation::Attachment.def().rev())
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
