use sea_orm::entity::prelude::*;
use uuid::Uuid;

#[derive(Clone, Debug, PartialEq, DeriveActiveEnum, EnumIter, serde::Serialize, serde::Deserialize)]
#[sea_orm(rs_type = "String", db_type = "Text")]
pub enum TripActivityAction {
    #[sea_orm(string_value = "insert")]
    Insert,
    #[sea_orm(string_value = "update")]
    Update,
    #[sea_orm(string_value = "delete")]
    Delete,
}

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "trip_activity")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: Uuid,
    pub trip_id: Uuid,
    pub entity_type: String,
    pub entity_id: Uuid,
    pub entity_label: Option<String>,
    pub action: TripActivityAction,
    pub actor_user_id: Option<Uuid>,
    pub occurred_at: DateTimeUtc,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::trip::Entity",
        from = "Column::TripId",
        to = "super::trip::Column::Id"
    )]
    Trip,
}

impl Related<super::trip::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Trip.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
