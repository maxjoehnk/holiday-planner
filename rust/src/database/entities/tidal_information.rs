use sea_orm::ActiveValue::Set;
use sea_orm::entity::prelude::*;
use uuid::Uuid;

#[derive(Clone, Debug, PartialEq, DeriveActiveEnum, EnumIter, serde::Serialize, serde::Deserialize)]
#[sea_orm(rs_type = "String", db_type = "Text")]
pub enum Tide {
    #[sea_orm(string_value = "high")]
    High,
    #[sea_orm(string_value = "low")]
    Low,
}

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "tidal_information")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: Uuid,
    pub location_id: Uuid,
    pub date: DateTimeUtc,
    pub height: f64,
    pub tide: Tide,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::location::Entity",
        from = "Column::LocationId",
        to = "super::location::Column::Id"
    )]
    Location,
}

impl Related<super::location::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Location.def()
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
