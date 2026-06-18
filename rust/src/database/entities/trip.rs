use sea_orm::ActiveValue::Set;
use sea_orm::entity::prelude::*;
use uuid::Uuid;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "trips")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: Uuid,
    pub name: String,
    pub start_date: chrono::DateTime<chrono::Utc>,
    pub end_date: chrono::DateTime<chrono::Utc>,
    pub header_image: Option<Vec<u8>>,
    pub updated_at: chrono::DateTime<chrono::Utc>,
    pub deleted_at: Option<chrono::DateTime<chrono::Utc>>,
    pub last_modified_by: Option<String>,
    pub owner_id: Option<String>,
    /// Set when the server-side trip has been deleted out from under
    /// us (e.g. the owner hard-deleted and our membership was
    /// cascaded away). The local row stays as a read-only snapshot.
    pub detached_at: Option<chrono::DateTime<chrono::Utc>>,
    /// Storage key for the header image blob, populated when the user
    /// sets a header. Once `header_image_uploaded_at` is non-null the
    /// blob is known to be on the server and the path is what other
    /// clients pull. `None` means no header image.
    pub header_image_path: Option<String>,
    pub header_image_sha256: Option<String>,
    pub header_image_uploaded_at: Option<chrono::DateTime<chrono::Utc>>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(has_many = "super::attachment::Entity")]
    Attachment
}

impl Related<super::attachment::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Attachment.def()
    }
}

impl Related<super::tag::Entity> for Entity {
    fn to() -> RelationDef {
        super::trip_tag::Relation::Tag.def()
    }
    
    fn via() -> Option<RelationDef> {
        Some(super::trip_tag::Relation::Trip.def().rev())
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
