use std::ops::Deref;
use crate::database::entities::attachment::{self, Entity as Attachment};
use sea_orm::{DerivePartialModel, EntityTrait, FromQueryResult, QueryFilter, QueryOrder, ColumnTrait};
use uuid::Uuid;
use crate::database::Database;

#[derive(Debug, Clone, DerivePartialModel, FromQueryResult)]
#[sea_orm(entity = "attachment::Entity")]
pub struct PartialAttachment {
    pub id: Uuid,
    pub name: String,
    pub file_name: String,
    pub content_type: String,
}

pub async fn find_all_by_trip(db: &Database, trip_id: Uuid) -> anyhow::Result<Vec<PartialAttachment>> {
    let attachments = Attachment::find()
        .filter(attachment::Column::TripId.eq(trip_id))
        .order_by_asc(attachment::Column::Name)
        .into_partial_model::<PartialAttachment>()
        .all(db.deref())
        .await?;

    Ok(attachments)
}

pub async fn find_by_id(db: &Database, id: Uuid) -> anyhow::Result<Option<attachment::Model>> {
    let attachment = Attachment::find_by_id(id)
        .one(db.deref())
        .await?;

    Ok(attachment)
}

pub async fn insert(db: &Database, model: attachment::ActiveModel) -> anyhow::Result<()> {
    Attachment::insert(model)
        .exec_without_returning(db.deref())
        .await?;
    
    Ok(())
}

pub async fn delete_by_id(db: &Database, id: Uuid) -> anyhow::Result<()> {
    Attachment::delete_by_id(id)
        .exec(db.deref())
        .await?;

    Ok(())
}
