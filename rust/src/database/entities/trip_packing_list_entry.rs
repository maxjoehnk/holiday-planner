use sea_orm::entity::prelude::*;
use uuid::Uuid;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "trip_packing_list_entries")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub trip_id: Uuid,
    #[sea_orm(primary_key)]
    pub packing_list_entry_id: Uuid,
    pub is_packed: bool,
    pub quantity: Option<i64>,
    pub override_quantity: Option<i64>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::trip::Entity",
        from = "Column::TripId",
        to = "super::trip::Column::Id"
    )]
    Trip,
    #[sea_orm(
        belongs_to = "super::packing_list_entry::Entity",
        from = "Column::PackingListEntryId",
        to = "super::packing_list_entry::Column::Id"
    )]
    PackingListEntry,
}

impl Related<super::trip::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Trip.def()
    }
}

impl Related<super::packing_list_entry::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::PackingListEntry.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
