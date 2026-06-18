use std::ops::Deref;

use chrono::NaiveDate;
use sea_orm::{ActiveValue::Set, ColumnTrait, EntityTrait, QueryFilter, QueryOrder};
use uuid::Uuid;

use crate::database::Database;
use crate::database::entities::trip_day::{self, Entity as TripDay};

pub async fn find_all_by_trip(db: &Database, trip_id: Uuid) -> anyhow::Result<Vec<trip_day::Model>> {
    let days = TripDay::find()
        .filter(trip_day::Column::TripId.eq(trip_id))
        .order_by_asc(trip_day::Column::Date)
        .all(db.deref())
        .await?;

    Ok(days)
}

pub async fn find_by_id(db: &Database, id: Uuid) -> anyhow::Result<Option<trip_day::Model>> {
    let day = TripDay::find_by_id(id).one(db.deref()).await?;
    Ok(day)
}

pub async fn find_by_trip_and_date(
    db: &Database,
    trip_id: Uuid,
    date: NaiveDate,
) -> anyhow::Result<Option<trip_day::Model>> {
    let day = TripDay::find()
        .filter(trip_day::Column::TripId.eq(trip_id))
        .filter(trip_day::Column::Date.eq(date))
        .one(db.deref())
        .await?;
    Ok(day)
}

pub async fn upsert(
    db: &Database,
    trip_id: Uuid,
    date: NaiveDate,
) -> anyhow::Result<trip_day::Model> {
    // Content-addressed id so two devices (or two members) materialising
    // the same (trip, date) trip_day arrive at the same row, both
    // locally and on the server. Without this, each device generates a
    // fresh uuid_v4 and the second push fails the server-side
    // `(trip_id, date)` unique constraint, leaving the loser with a
    // local-only id that orphans its trip_day_locations / attached
    // POIs and routes.
    let id = crate::sync::wire::trip_day_id_for(trip_id, date);
    if let Some(existing) = TripDay::find_by_id(id).one(db.deref()).await? {
        return Ok(existing);
    }
    // Fall back to the (trip_id, date) lookup in case a legacy row
    // exists with a random uuid_v4 (created before the deterministic
    // scheme was rolled out). New deployments hit this branch never.
    if let Some(existing) = find_by_trip_and_date(db, trip_id, date).await? {
        return Ok(existing);
    }

    let now = chrono::Utc::now();
    let model = trip_day::ActiveModel {
        id: Set(id),
        trip_id: Set(trip_id),
        date: Set(date),
        title: Set(None),
        updated_at: Set(now),
        deleted_at: Set(None),
        last_modified_by: Set(
            crate::sync::session::current_user().await.map(|u| u.to_string()),
        ),
    };
    TripDay::insert(model)
        .exec_without_returning(db.deref())
        .await?;

    let day = TripDay::find_by_id(id)
        .one(db.deref())
        .await?
        .ok_or_else(|| anyhow::anyhow!("inserted trip_day vanished"))?;
    Ok(day)
}

pub async fn update_title(db: &Database, id: Uuid, title: Option<String>) -> anyhow::Result<()> {
    let now = chrono::Utc::now();
    TripDay::update(trip_day::ActiveModel {
        id: Set(id),
        title: Set(title),
        updated_at: Set(now),
        last_modified_by: Set(
            crate::sync::session::current_user().await.map(|u| u.to_string()),
        ),
        ..Default::default()
    })
    .exec(db.deref())
    .await?;
    Ok(())
}

pub async fn delete_by_id(db: &Database, id: Uuid) -> anyhow::Result<()> {
    TripDay::delete_by_id(id).exec(db.deref()).await?;
    Ok(())
}

pub async fn find_outside_range(
    db: &Database,
    trip_id: Uuid,
    start: NaiveDate,
    end: NaiveDate,
) -> anyhow::Result<Vec<trip_day::Model>> {
    let days = TripDay::find()
        .filter(trip_day::Column::TripId.eq(trip_id))
        .filter(
            trip_day::Column::Date
                .lt(start)
                .or(trip_day::Column::Date.gt(end)),
        )
        .all(db.deref())
        .await?;
    Ok(days)
}
