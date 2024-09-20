use sea_orm::ActiveValue::Set;
use sea_orm::entity::prelude::*;
use uuid::Uuid;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "packing_list_entries")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub quantity_per_day: Option<i64>,
    pub quantity_per_night: Option<i64>,
    pub quantity_fixed: Option<i64>,
    pub group_id: Option<Uuid>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::packing_list_group::Entity",
        from = "Column::GroupId",
        to = "super::packing_list_group::Column::Id"
    )]
    Group,
    #[sea_orm(has_many = "super::packing_list_condition::Entity")]
    Conditions,
}

impl Related<super::packing_list_group::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Group.def()
    }
}

impl Related<super::packing_list_condition::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Conditions.def()
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
