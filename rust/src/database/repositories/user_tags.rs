use std::ops::Deref;

use sea_orm::ActiveValue::Set;
use sea_orm::{ColumnTrait, EntityTrait, QueryFilter};
use uuid::Uuid;

use crate::database::entities::user_tag::{self, Entity as UserTag};
use crate::database::Database;

/// Insert a user_tag row if absent. Idempotent — re-running with the
/// same (user, tag) pair is a no-op.
pub async fn ensure(db: &Database, user_id: Uuid, tag_id: Uuid) -> anyhow::Result<bool> {
    if UserTag::find_by_id((user_id, tag_id))
        .one(db.deref())
        .await?
        .is_some()
    {
        return Ok(false);
    }
    let now = chrono::Utc::now();
    let model = user_tag::ActiveModel {
        user_id: Set(user_id),
        tag_id: Set(tag_id),
        added_at: Set(now),
        updated_at: Set(now),
        deleted_at: Set(None),
    };
    UserTag::insert(model)
        .exec_without_returning(db.deref())
        .await?;
    Ok(true)
}

pub async fn find_by_id(
    db: &Database,
    user_id: Uuid,
    tag_id: Uuid,
) -> anyhow::Result<Option<user_tag::Model>> {
    Ok(UserTag::find_by_id((user_id, tag_id))
        .one(db.deref())
        .await?)
}

pub async fn find_tag_ids_for_user(db: &Database, user_id: Uuid) -> anyhow::Result<Vec<Uuid>> {
    let rows = UserTag::find()
        .filter(user_tag::Column::UserId.eq(user_id))
        .all(db.deref())
        .await?;
    Ok(rows.into_iter().map(|r| r.tag_id).collect())
}
