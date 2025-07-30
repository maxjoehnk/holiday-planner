use sea_orm::ActiveValue::Set;
use uuid::Uuid;
use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "tags")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: Uuid,
    pub name: String,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(has_many = "super::trip_tag::Entity")]
    TripTag,
    #[sea_orm(has_many = "super::packing_list_condition::Entity")]
    PackingListCondition,
}

impl Related<super::trip_tag::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::TripTag.def()
    }
}

impl Related<super::trip::Entity> for Entity {
    fn to() -> RelationDef {
        super::trip_tag::Relation::Trip.def()
    }
    
    fn via() -> Option<RelationDef> {
        Some(super::trip_tag::Relation::Tag.def().rev())
    }
}

impl Related<super::packing_list_condition::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::PackingListCondition.def()
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
