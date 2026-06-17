use std::ops::Deref;

use sea_orm::{ActiveValue::Set, ColumnTrait, EntityTrait, QueryFilter, QueryOrder};
use uuid::Uuid;

use crate::database::Database;
use crate::database::entities::trip_day_location::{self, Entity as TripDayLocation};

pub async fn find_by_day(
    db: &Database,
    trip_day_id: Uuid,
) -> anyhow::Result<Vec<trip_day_location::Model>> {
    let rows = TripDayLocation::find()
        .filter(trip_day_location::Column::TripDayId.eq(trip_day_id))
        .order_by_asc(trip_day_location::Column::DisplayOrder)
        .all(db.deref())
        .await?;
    Ok(rows)
}

pub async fn find_by_days(
    db: &Database,
    trip_day_ids: &[Uuid],
) -> anyhow::Result<Vec<trip_day_location::Model>> {
    if trip_day_ids.is_empty() {
        return Ok(Vec::new());
    }
    let rows = TripDayLocation::find()
        .filter(trip_day_location::Column::TripDayId.is_in(trip_day_ids.to_vec()))
        .order_by_asc(trip_day_location::Column::TripDayId)
        .order_by_asc(trip_day_location::Column::DisplayOrder)
        .all(db.deref())
        .await?;
    Ok(rows)
}

pub async fn insert(
    db: &Database,
    trip_day_id: Uuid,
    location_id: Uuid,
    is_primary: bool,
    display_order: i32,
) -> anyhow::Result<()> {
    let model = trip_day_location::ActiveModel {
        trip_day_id: Set(trip_day_id),
        location_id: Set(location_id),
        is_primary: Set(is_primary),
        display_order: Set(display_order),
        updated_at: Set(chrono::Utc::now()),
        deleted_at: Set(None),
    };
    TripDayLocation::insert(model)
        .exec_without_returning(db.deref())
        .await?;
    Ok(())
}

pub async fn delete(db: &Database, trip_day_id: Uuid, location_id: Uuid) -> anyhow::Result<()> {
    TripDayLocation::delete_by_id((trip_day_id, location_id))
        .exec(db.deref())
        .await?;
    Ok(())
}

pub async fn delete_all_for_day(db: &Database, trip_day_id: Uuid) -> anyhow::Result<()> {
    TripDayLocation::delete_many()
        .filter(trip_day_location::Column::TripDayId.eq(trip_day_id))
        .exec(db.deref())
        .await?;
    Ok(())
}

pub async fn clear_primary(db: &Database, trip_day_id: Uuid) -> anyhow::Result<()> {
    TripDayLocation::update_many()
        .col_expr(
            trip_day_location::Column::IsPrimary,
            sea_orm::sea_query::Expr::value(false),
        )
        .filter(trip_day_location::Column::TripDayId.eq(trip_day_id))
        .exec(db.deref())
        .await?;
    Ok(())
}

pub async fn set_primary(
    db: &Database,
    trip_day_id: Uuid,
    location_id: Uuid,
) -> anyhow::Result<()> {
    TripDayLocation::update(trip_day_location::ActiveModel {
        trip_day_id: Set(trip_day_id),
        location_id: Set(location_id),
        is_primary: Set(true),
        updated_at: Set(chrono::Utc::now()),
        ..Default::default()
    })
    .exec(db.deref())
    .await?;
    Ok(())
}

pub async fn set_display_order(
    db: &Database,
    trip_day_id: Uuid,
    location_id: Uuid,
    display_order: i32,
) -> anyhow::Result<()> {
    TripDayLocation::update(trip_day_location::ActiveModel {
        trip_day_id: Set(trip_day_id),
        location_id: Set(location_id),
        display_order: Set(display_order),
        updated_at: Set(chrono::Utc::now()),
        ..Default::default()
    })
    .exec(db.deref())
    .await?;
    Ok(())
}
