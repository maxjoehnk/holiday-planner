use chrono::{DateTime, Utc};
use uuid::Uuid;

#[derive(Debug, Clone, Copy)]
pub enum SchedulableItemType {
    PointOfInterest,
    Route,
}

#[derive(Debug)]
pub struct AssignItemToDay {
    pub trip_id: Uuid,
    pub item_type: SchedulableItemType,
    pub item_id: Uuid,
    pub date: DateTime<Utc>,
    pub scheduled_at: Option<DateTime<Utc>>,
}

#[derive(Debug)]
pub struct UnassignItem {
    pub item_type: SchedulableItemType,
    pub item_id: Uuid,
}

#[derive(Debug)]
pub struct OrderedItem {
    pub item_type: SchedulableItemType,
    pub item_id: Uuid,
}

#[derive(Debug)]
pub struct ReorderDay {
    pub trip_day_id: Uuid,
    pub ordered_items: Vec<OrderedItem>,
}

#[derive(Debug)]
pub struct SetTripDayTitle {
    pub trip_id: Uuid,
    pub date: DateTime<Utc>,
    pub title: Option<String>,
}

#[derive(Debug)]
pub struct AddTripDayLocation {
    pub trip_id: Uuid,
    pub date: DateTime<Utc>,
    pub location_id: Uuid,
}

#[derive(Debug)]
pub struct RemoveTripDayLocation {
    pub trip_day_id: Uuid,
    pub location_id: Uuid,
}

#[derive(Debug)]
pub struct SetPrimaryTripDayLocation {
    pub trip_day_id: Uuid,
    pub location_id: Uuid,
}
