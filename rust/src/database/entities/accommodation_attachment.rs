use sea_orm::entity::prelude::*;
use uuid::Uuid;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "accommodation_attachments")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub accommodation_id: Uuid,
    #[sea_orm(primary_key)]
    pub attachment_id: Uuid,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::accommodation::Entity",
        from = "Column::AccommodationId",
        to = "super::accommodation::Column::Id"
    )]
    Accommodation,
    #[sea_orm(
        belongs_to = "super::attachment::Entity",
        from = "Column::AttachmentId",
        to = "super::attachment::Column::Id"
    )]
    Attachment,
}

impl Related<super::attachment::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Attachment.def()
    }
}

impl Related<super::accommodation::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Accommodation.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
