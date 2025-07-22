use std::ops::Deref;
use crate::database::entities::attachment::{self, Entity as Attachment};
use crate::database::entities::accommodation_attachment::{self, Entity as AccommodationAttachment};
use sea_orm::{DerivePartialModel, EntityTrait, FromQueryResult, QueryFilter, QueryOrder, ColumnTrait, RelationTrait, JoinType, QuerySelect, ConnectionTrait};
use uuid::Uuid;
use crate::database::{Database, DbResult};

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

pub async fn insert(db: &impl ConnectionTrait, model: attachment::ActiveModel) -> DbResult<()> {
    Attachment::insert(model)
        .exec_without_returning(db)
        .await?;
    
    Ok(())
}

pub async fn delete_by_id(db: &impl ConnectionTrait, id: Uuid) -> DbResult<()> {
    Attachment::delete_by_id(id)
        .exec(db)
        .await?;

    Ok(())
}

pub async fn find_all_by_accommodation(db: &impl ConnectionTrait, accommodation_id: Uuid) -> anyhow::Result<Vec<PartialAttachment>> {
    let attachments = Attachment::find()
        .join_as(
            JoinType::InnerJoin,
            attachment::Relation::AccommodationAttachment.def(),
            accommodation_attachment::Entity
        )
        .filter(accommodation_attachment::Column::AccommodationId.eq(accommodation_id))
        .order_by_asc(attachment::Column::Name)
        .into_partial_model::<PartialAttachment>()
        .all(db)
        .await?;

    Ok(attachments)
}

pub async fn add_to_accommodation(db: &impl ConnectionTrait, accommodation_id: Uuid, attachment_id: Uuid) -> DbResult<()> {
    let model = accommodation_attachment::ActiveModel {
        accommodation_id: sea_orm::ActiveValue::Set(accommodation_id),
        attachment_id: sea_orm::ActiveValue::Set(attachment_id),
    };

    AccommodationAttachment::insert(model)
        .exec_without_returning(db)
        .await?;
    
    Ok(())
}

pub async fn remove_from_accommodation(db: &impl ConnectionTrait, accommodation_id: Uuid, attachment_id: Uuid) -> DbResult<()> {
    AccommodationAttachment::delete_by_id((accommodation_id, attachment_id))
        .exec(db)
        .await?;
    
    Ok(())
}
