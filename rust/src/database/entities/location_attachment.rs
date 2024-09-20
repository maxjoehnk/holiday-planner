use sea_orm::entity::prelude::*;
use uuid::Uuid;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "location_attachments")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub location_id: Uuid,
    #[sea_orm(primary_key)]
    pub attachment_id: Uuid,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::location::Entity",
        from = "Column::LocationId",
        to = "super::location::Column::Id"
    )]
    Location,
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

impl Related<super::location::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Location.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
