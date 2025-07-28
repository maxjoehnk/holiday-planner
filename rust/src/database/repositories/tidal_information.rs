use std::ops::Deref;
use crate::database::entities::{tidal_information};
use crate::database::entities::tidal_information::{Entity as TidalInformation};
use sea_orm::{EntityTrait, QueryFilter, ColumnTrait, ActiveModelTrait, Set, QueryOrder, ConnectionTrait};
use uuid::Uuid;
use crate::database::{Database, DbResult};
use chrono::{DateTime, Utc};
use crate::models::TideType;

pub async fn find_all_by_location_id(db: &Database, location_id: Uuid) -> DbResult<Vec<tidal_information::Model>> {
    let tidal_info = TidalInformation::find()
        .filter(tidal_information::Column::LocationId.eq(location_id))
        .order_by_asc(tidal_information::Column::Date)
        .all(db.deref())
        .await?;

    Ok(tidal_info)
}

pub async fn insert_multiple_tide_records(db: &impl ConnectionTrait, location_id: Uuid, tide_records: Vec<(DateTime<Utc>, f64, TideType)>) -> DbResult<()> {
    delete_by_location_id(db, location_id).await?;
    
    let models: Vec<tidal_information::ActiveModel> = tide_records
        .into_iter()
        .map(|(date, height, tide)| tidal_information::ActiveModel {
            id: Set(Uuid::new_v4()),
            location_id: Set(location_id),
            date: Set(date),
            height: Set(height),
            tide: Set(tide.into()),
        })
        .collect();

    if !models.is_empty() {
        TidalInformation::insert_many(models)
            .exec_without_returning(db)
            .await?;
    }
    
    Ok(())
}

pub async fn delete_by_location_id(db: &impl ConnectionTrait, location_id: Uuid) -> DbResult<()> {
    TidalInformation::delete_many()
        .filter(tidal_information::Column::LocationId.eq(location_id))
        .exec(db)
        .await?;

    Ok(())
}
