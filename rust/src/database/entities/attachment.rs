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
    pub updated_at: DateTimeUtc,
    pub deleted_at: Option<DateTimeUtc>,
    pub last_modified_by: Option<String>,
    /// Storage object key (e.g. `trips/<trip_id>/<attachment_id>`).
    /// `None` when the row is still local-only (no sync push yet).
    pub storage_path: Option<String>,
    /// Hex SHA-256 of `data`, used to short-circuit re-uploads and verify
    /// downloads.
    pub sha256: Option<String>,
    /// When this device last successfully pushed the blob to Supabase
    /// Storage. `None` means a re-upload is pending.
    pub uploaded_at: Option<DateTimeUtc>,
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
