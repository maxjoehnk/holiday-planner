use sea_orm::ActiveValue::Set;
use sea_orm::entity::prelude::*;
use uuid::Uuid;

#[derive(Clone, Debug, PartialEq, DeriveActiveEnum, EnumIter, serde::Serialize, serde::Deserialize)]
#[sea_orm(rs_type = "String", db_type = "Text")]
pub enum MutationOperation {
    #[sea_orm(string_value = "insert")]
    Insert,
    #[sea_orm(string_value = "update")]
    Update,
    #[sea_orm(string_value = "delete")]
    Delete,
}

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "pending_mutations")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub entity_type: String,
    pub entity_id: Uuid,
    pub operation: MutationOperation,
    pub payload: String,
    pub created_at: DateTimeUtc,
    pub attempts: i32,
    pub last_error: Option<String>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {
    fn new() -> Self {
        Self {
            id: Set(Uuid::new_v4()),
            created_at: Set(chrono::Utc::now()),
            attempts: Set(0),
            ..ActiveModelTrait::default()
        }
    }
}
