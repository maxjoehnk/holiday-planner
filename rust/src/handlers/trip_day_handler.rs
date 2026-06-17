use std::collections::HashMap;

use anyhow::Context;
use chrono::{DateTime, Local, NaiveDate, TimeZone, Utc};
use uuid::Uuid;

use crate::api::events::{DataChangeEvent, emit};
use crate::commands::{
    AddTripDayLocation, AssignItemToDay, RemoveTripDayLocation, ReorderDay,
    SchedulableItemType, SetPrimaryTripDayLocation, SetTripDayTitle, UnassignItem,
};
use crate::database::entities::pending_mutation::MutationOperation;
use crate::database::{Database, repositories};
use crate::handlers::Handler;
use crate::sync;
use crate::models::{
    Coordinate, DayItem, DayItemDetails, DayLocation, DayWeather, TripDayView, UnassignedItems,
    UnassignedPoi, UnassignedRoute,
};

pub struct TripDayHandler {
    db: Database,
}

impl Handler for TripDayHandler {
    fn create(db: Database) -> Self {
        Self { db }
    }
}

impl TripDayHandler {
    pub async fn get_trip_days(&self, trip_id: Uuid) -> anyhow::Result<Vec<TripDayView>> {
        let trip = repositories::trips::find_by_id(&self.db, trip_id)
            .await?
            .context("Trip not found")?;

        let start = to_local_date(trip.start_date);
        let end = to_local_date(trip.end_date);

        let trip_days = repositories::trip_days::find_all_by_trip(&self.db, trip_id).await?;
        let day_ids: Vec<Uuid> = trip_days.iter().map(|d| d.id).collect();
        let day_by_date: HashMap<NaiveDate, &crate::database::entities::trip_day::Model> =
            trip_days.iter().map(|d| (d.date, d)).collect();

        let day_locations =
            repositories::trip_day_locations::find_by_days(&self.db, &day_ids).await?;
        let locations = repositories::locations::find_all_by_trip(&self.db, trip_id).await?;
        let location_by_id: HashMap<Uuid, &crate::database::entities::location::Model> =
            locations.iter().map(|l| (l.id, l)).collect();

        let mut day_locations_by_day: HashMap<Uuid, Vec<DayLocation>> = HashMap::new();
        for entry in &day_locations {
            if let Some(loc) = location_by_id.get(&entry.location_id) {
                day_locations_by_day
                    .entry(entry.trip_day_id)
                    .or_default()
                    .push(DayLocation {
                        location_id: loc.id,
                        city: loc.city.clone(),
                        country: loc.country.clone(),
                        coordinates: Coordinate {
                            latitude: loc.coordinates_latitude,
                            longitude: loc.coordinates_longitude,
                        },
                        is_primary: entry.is_primary,
                    });
            }
        }

        let pois = repositories::points_of_interest::find_assigned_by_trip(&self.db, trip_id).await?;
        let routes = repositories::routes::find_assigned_by_trip(&self.db, trip_id).await?;

        let accommodations =
            repositories::accommodations::find_all_by_trip(&self.db, trip_id).await?;
        let trains =
            repositories::transits::find_all_trains_by_trip(&self.db, trip_id).await?;
        let reservations =
            repositories::bookings::find_all_reservations_by_trip(&self.db, trip_id).await?;
        let car_rentals =
            repositories::bookings::find_all_car_rentals_by_trip(&self.db, trip_id).await?;

        let mut items_by_date: HashMap<NaiveDate, Vec<DayItem>> = HashMap::new();
        let mut items_by_day_id: HashMap<Uuid, Vec<DayItem>> = HashMap::new();

        for poi in pois {
            if let (Some(day_id), Some(order)) = (poi.trip_day_id, poi.day_order) {
                items_by_day_id.entry(day_id).or_default().push(DayItem {
                    scheduled_at: poi.scheduled_at,
                    details: DayItemDetails::PointOfInterest {
                        id: poi.id,
                        name: poi.name,
                        address: poi.address,
                        day_order: order,
                    },
                });
            }
        }
        for route in routes {
            if let (Some(day_id), Some(order)) = (route.trip_day_id, route.day_order) {
                items_by_day_id.entry(day_id).or_default().push(DayItem {
                    scheduled_at: route.scheduled_at,
                    details: DayItemDetails::Route {
                        id: route.id,
                        name: route.name,
                        sport: route.sport,
                        distance_meters: route.distance_meters,
                        duration_seconds: route.duration_seconds,
                        day_order: order,
                    },
                });
            }
        }

        for accom in &accommodations {
            if let Some(check_in) = accom.check_in {
                items_by_date
                    .entry(to_local_date(check_in))
                    .or_default()
                    .push(DayItem {
                        scheduled_at: Some(check_in),
                        details: DayItemDetails::AccommodationCheckIn {
                            accommodation_id: accom.id,
                            name: accom.name.clone(),
                            address: accom.address.clone(),
                            check_in,
                        },
                    });
            }
            if let Some(check_out) = accom.check_out {
                items_by_date
                    .entry(to_local_date(check_out))
                    .or_default()
                    .push(DayItem {
                        scheduled_at: Some(check_out),
                        details: DayItemDetails::AccommodationCheckOut {
                            accommodation_id: accom.id,
                            name: accom.name.clone(),
                            address: accom.address.clone(),
                            check_out,
                        },
                    });
            }
            if let (Some(check_in), Some(check_out)) = (accom.check_in, accom.check_out) {
                let check_in_date = to_local_date(check_in);
                let check_out_date = to_local_date(check_out);
                let mut day = check_in_date
                    .succ_opt()
                    .unwrap_or(check_in_date);
                while day < check_out_date {
                    items_by_date.entry(day).or_default().push(DayItem {
                        scheduled_at: None,
                        details: DayItemDetails::AccommodationStay {
                            accommodation_id: accom.id,
                            name: accom.name.clone(),
                        },
                    });
                    day = match day.succ_opt() {
                        Some(d) => d,
                        None => break,
                    };
                }
            }
        }

        for train in trains {
            items_by_date
                .entry(to_local_date(train.scheduled_departure_time))
                .or_default()
                .push(DayItem {
                    scheduled_at: Some(train.scheduled_departure_time),
                    details: DayItemDetails::TrainDeparture {
                        train_id: train.id,
                        station: train.departure_station_name.clone(),
                        train_number: train.train_number.clone(),
                        seat: None,
                        scheduled: train.scheduled_departure_time,
                    },
                });
            if to_local_date(train.scheduled_arrival_time) != to_local_date(train.scheduled_departure_time) {
                items_by_date
                    .entry(to_local_date(train.scheduled_arrival_time))
                    .or_default()
                    .push(DayItem {
                        scheduled_at: Some(train.scheduled_arrival_time),
                        details: DayItemDetails::TrainArrival {
                            train_id: train.id,
                            station: train.arrival_station_name,
                            train_number: train.train_number,
                            scheduled: train.scheduled_arrival_time,
                        },
                    });
            }
        }

        for reservation in reservations {
            items_by_date
                .entry(to_local_date(reservation.start_date))
                .or_default()
                .push(DayItem {
                    scheduled_at: Some(reservation.start_date),
                    details: DayItemDetails::Reservation {
                        reservation_id: reservation.id,
                        title: reservation.title,
                        address: reservation.address,
                        category: reservation.category.into(),
                        start: reservation.start_date,
                        end: reservation.end_date,
                    },
                });
        }

        for car_rental in car_rentals {
            items_by_date
                .entry(to_local_date(car_rental.pick_up_date))
                .or_default()
                .push(DayItem {
                    scheduled_at: Some(car_rental.pick_up_date),
                    details: DayItemDetails::CarRentalPickUp {
                        car_rental_id: car_rental.id,
                        provider: car_rental.provider.clone(),
                        address: car_rental.pick_up_location.clone(),
                        pick_up: car_rental.pick_up_date,
                    },
                });
            if to_local_date(car_rental.return_date) != to_local_date(car_rental.pick_up_date) {
                items_by_date
                    .entry(to_local_date(car_rental.return_date))
                    .or_default()
                    .push(DayItem {
                        scheduled_at: Some(car_rental.return_date),
                        details: DayItemDetails::CarRentalDropOff {
                            car_rental_id: car_rental.id,
                            provider: car_rental.provider,
                            address: car_rental.return_location,
                            drop_off: car_rental.return_date,
                        },
                    });
            }
        }

        let weather_by_location = self.load_weather_by_location(trip_id).await?;
        let weather_by_accommodation = self.load_weather_by_accommodation(trip_id).await?;
        tracing::debug!(
            trip_id = %trip_id,
            location_entries = weather_by_location.len(),
            accommodation_entries = weather_by_accommodation.len(),
            "trip_day_handler: loaded weather map"
        );

        let mut views: Vec<TripDayView> = Vec::new();
        let mut current = start;
        let mut day_index = 1i32;
        while current <= end {
            let trip_day = day_by_date.get(&current).copied();
            let id = trip_day.map(|d| d.id);
            let title = trip_day.and_then(|d| d.title.clone());

            let mut locations = trip_day
                .and_then(|d| day_locations_by_day.get(&d.id))
                .cloned()
                .unwrap_or_default();
            locations.sort_by(|a, b| b.is_primary.cmp(&a.is_primary));

            let primary_location = locations
                .iter()
                .find(|l| l.is_primary)
                .or_else(|| locations.first());
            let location_weather = primary_location
                .and_then(|loc| weather_by_location.get(&(loc.location_id, current)))
                .cloned();
            let weather = location_weather.or_else(|| {
                if primary_location.is_some() {
                    return None;
                }
                accommodations
                    .iter()
                    .find(|a| match (a.check_in, a.check_out) {
                        (Some(check_in), Some(check_out)) => {
                            let in_date = to_local_date(check_in);
                            let out_date = to_local_date(check_out);
                            current >= in_date && current <= out_date
                        }
                        _ => false,
                    })
                    .and_then(|a| weather_by_accommodation.get(&(a.id, current)))
                    .cloned()
            });

            let mut items = items_by_date.remove(&current).unwrap_or_default();
            if let Some(day) = trip_day {
                if let Some(extra) = items_by_day_id.remove(&day.id) {
                    items.extend(extra);
                }
            }
            items.sort_by(|a, b| {
                let order_a = a.day_order();
                let order_b = b.day_order();
                match (order_a, order_b) {
                    (Some(x), Some(y)) => x.cmp(&y),
                    (Some(_), None) => std::cmp::Ordering::Greater,
                    (None, Some(_)) => std::cmp::Ordering::Less,
                    (None, None) => a.scheduled_at.cmp(&b.scheduled_at),
                }
            });

            views.push(TripDayView {
                id,
                trip_id,
                date: date_to_datetime(current),
                day_index,
                title,
                locations,
                weather,
                items,
            });

            day_index += 1;
            current = match current.succ_opt() {
                Some(d) => d,
                None => break,
            };
        }

        Ok(views)
    }

    pub async fn get_unassigned_items(&self, trip_id: Uuid) -> anyhow::Result<UnassignedItems> {
        let pois = repositories::points_of_interest::find_unassigned_by_trip(&self.db, trip_id).await?;
        let routes = repositories::routes::find_unassigned_by_trip(&self.db, trip_id).await?;

        Ok(UnassignedItems {
            points_of_interest: pois
                .into_iter()
                .map(|p| UnassignedPoi {
                    id: p.id,
                    name: p.name,
                    address: p.address,
                })
                .collect(),
            routes: routes
                .into_iter()
                .map(|r| UnassignedRoute {
                    id: r.id,
                    name: r.name,
                    sport: r.sport,
                    distance_meters: r.distance_meters,
                    duration_seconds: r.duration_seconds,
                })
                .collect(),
        })
    }

    pub async fn assign_item_to_day(&self, command: AssignItemToDay) -> anyhow::Result<()> {
        let date = to_local_date(command.date);
        let day = repositories::trip_days::upsert(&self.db, command.trip_id, date).await?;
        enqueue_trip_day(&self.db, day.id).await?;
        let next_order = self.next_day_order(day.id).await?;
        match command.item_type {
            SchedulableItemType::PointOfInterest => {
                repositories::points_of_interest::assign_to_day(
                    &self.db,
                    command.item_id,
                    day.id,
                    next_order,
                    command.scheduled_at,
                )
                .await?;
                enqueue_poi(&self.db, command.item_id).await?;
                emit(DataChangeEvent::PoisChanged {
                    trip_id: Some(command.trip_id),
                });
            }
            SchedulableItemType::Route => {
                repositories::routes::assign_to_day(
                    &self.db,
                    command.item_id,
                    day.id,
                    next_order,
                    command.scheduled_at,
                )
                .await?;
                enqueue_route(&self.db, command.item_id).await?;
                emit(DataChangeEvent::RoutesChanged {
                    trip_id: Some(command.trip_id),
                });
            }
        }
        emit(DataChangeEvent::TripDaysChanged {
            trip_id: command.trip_id,
        });
        Ok(())
    }

    pub async fn unassign_item(&self, trip_id: Uuid, command: UnassignItem) -> anyhow::Result<()> {
        match command.item_type {
            SchedulableItemType::PointOfInterest => {
                repositories::points_of_interest::unassign(&self.db, command.item_id).await?;
                enqueue_poi(&self.db, command.item_id).await?;
                emit(DataChangeEvent::PoisChanged {
                    trip_id: Some(trip_id),
                });
            }
            SchedulableItemType::Route => {
                repositories::routes::unassign(&self.db, command.item_id).await?;
                enqueue_route(&self.db, command.item_id).await?;
                emit(DataChangeEvent::RoutesChanged {
                    trip_id: Some(trip_id),
                });
            }
        }
        emit(DataChangeEvent::TripDaysChanged { trip_id });
        Ok(())
    }

    pub async fn reorder_day(&self, trip_id: Uuid, command: ReorderDay) -> anyhow::Result<()> {
        for (index, item) in command.ordered_items.iter().enumerate() {
            let order = index as i32;
            match item.item_type {
                SchedulableItemType::PointOfInterest => {
                    repositories::points_of_interest::set_day_order(
                        &self.db,
                        item.item_id,
                        order,
                    )
                    .await?;
                    enqueue_poi(&self.db, item.item_id).await?;
                }
                SchedulableItemType::Route => {
                    repositories::routes::set_day_order(&self.db, item.item_id, order).await?;
                    enqueue_route(&self.db, item.item_id).await?;
                }
            }
        }
        emit(DataChangeEvent::TripDaysChanged { trip_id });
        Ok(())
    }

    pub async fn set_title(&self, command: SetTripDayTitle) -> anyhow::Result<()> {
        let trimmed = command.title.as_deref().map(str::trim);
        let title = trimmed
            .filter(|t| !t.is_empty())
            .map(|t| t.to_string());

        let date = to_local_date(command.date);
        let existing =
            repositories::trip_days::find_by_trip_and_date(&self.db, command.trip_id, date)
                .await?;

        match (existing, title) {
            (Some(day), Some(new_title)) => {
                repositories::trip_days::update_title(&self.db, day.id, Some(new_title)).await?;
                enqueue_trip_day(&self.db, day.id).await?;
            }
            (Some(day), None) => {
                let locations =
                    repositories::trip_day_locations::find_by_day(&self.db, day.id).await?;
                if locations.is_empty() && !self.day_has_items(day.id).await? {
                    repositories::trip_days::delete_by_id(&self.db, day.id).await?;
                    enqueue_trip_day_delete(&self.db, day.id).await?;
                } else {
                    repositories::trip_days::update_title(&self.db, day.id, None).await?;
                    enqueue_trip_day(&self.db, day.id).await?;
                }
            }
            (None, Some(new_title)) => {
                let day =
                    repositories::trip_days::upsert(&self.db, command.trip_id, date)
                        .await?;
                repositories::trip_days::update_title(&self.db, day.id, Some(new_title)).await?;
                enqueue_trip_day(&self.db, day.id).await?;
            }
            (None, None) => {}
        }
        emit(DataChangeEvent::TripDaysChanged {
            trip_id: command.trip_id,
        });
        Ok(())
    }

    pub async fn add_location(&self, command: AddTripDayLocation) -> anyhow::Result<()> {
        let date = to_local_date(command.date);
        let day = repositories::trip_days::upsert(&self.db, command.trip_id, date).await?;
        enqueue_trip_day(&self.db, day.id).await?;
        let existing =
            repositories::trip_day_locations::find_by_day(&self.db, day.id).await?;
        let is_first = existing.is_empty();
        let next_order = existing
            .iter()
            .map(|e| e.display_order)
            .max()
            .map(|m| m + 1)
            .unwrap_or(0);

        repositories::trip_day_locations::insert(
            &self.db,
            day.id,
            command.location_id,
            is_first,
            next_order,
        )
        .await?;
        enqueue_trip_day_location(&self.db, day.id, command.location_id).await?;

        emit(DataChangeEvent::TripDaysChanged {
            trip_id: command.trip_id,
        });
        Ok(())
    }

    pub async fn remove_location(
        &self,
        trip_id: Uuid,
        command: RemoveTripDayLocation,
    ) -> anyhow::Result<()> {
        let removed_was_primary = repositories::trip_day_locations::find_by_day(
            &self.db,
            command.trip_day_id,
        )
        .await?
        .into_iter()
        .find(|e| e.location_id == command.location_id)
        .map(|e| e.is_primary)
        .unwrap_or(false);

        repositories::trip_day_locations::delete(
            &self.db,
            command.trip_day_id,
            command.location_id,
        )
        .await?;
        enqueue_trip_day_location_delete(&self.db, command.trip_day_id, command.location_id).await?;

        if removed_was_primary {
            let remaining =
                repositories::trip_day_locations::find_by_day(&self.db, command.trip_day_id)
                    .await?;
            if let Some(first) = remaining.into_iter().next() {
                repositories::trip_day_locations::set_primary(
                    &self.db,
                    command.trip_day_id,
                    first.location_id,
                )
                .await?;
                enqueue_trip_day_location(&self.db, command.trip_day_id, first.location_id).await?;
            }
        }
        emit(DataChangeEvent::TripDaysChanged { trip_id });
        Ok(())
    }

    pub async fn set_primary_location(
        &self,
        trip_id: Uuid,
        command: SetPrimaryTripDayLocation,
    ) -> anyhow::Result<()> {
        // Snapshot the previous primary so we know which row to enqueue
        // alongside the new one.
        let prior_primary = repositories::trip_day_locations::find_by_day(
            &self.db,
            command.trip_day_id,
        )
        .await?
        .into_iter()
        .find(|e| e.is_primary)
        .map(|e| e.location_id);

        repositories::trip_day_locations::clear_primary(&self.db, command.trip_day_id).await?;
        repositories::trip_day_locations::set_primary(
            &self.db,
            command.trip_day_id,
            command.location_id,
        )
        .await?;
        if let Some(prev) = prior_primary {
            if prev != command.location_id {
                enqueue_trip_day_location(&self.db, command.trip_day_id, prev).await?;
            }
        }
        enqueue_trip_day_location(&self.db, command.trip_day_id, command.location_id).await?;
        emit(DataChangeEvent::TripDaysChanged { trip_id });
        Ok(())
    }

    pub async fn reconcile_after_trip_date_change(&self, trip_id: Uuid) -> anyhow::Result<()> {
        let trip = repositories::trips::find_by_id(&self.db, trip_id)
            .await?
            .context("Trip not found")?;
        let start = to_local_date(trip.start_date);
        let end = to_local_date(trip.end_date);

        let orphan_days =
            repositories::trip_days::find_outside_range(&self.db, trip_id, start, end).await?;
        if orphan_days.is_empty() {
            return Ok(());
        }
        let day_ids: Vec<Uuid> = orphan_days.iter().map(|d| d.id).collect();

        // Snapshot the items + locations on each orphan day so we can
        // enqueue per-row deletions after the bulk wipe.
        use sea_orm::{ColumnTrait, EntityTrait, QueryFilter};
        use std::ops::Deref;
        let pois_to_unassign: Vec<Uuid> = crate::database::entities::point_of_interest::Entity::find()
            .filter(crate::database::entities::point_of_interest::Column::TripDayId.is_in(day_ids.clone()))
            .all(self.db.deref())
            .await?
            .into_iter()
            .map(|p| p.id)
            .collect();
        let routes_to_unassign: Vec<Uuid> = crate::database::entities::route::Entity::find()
            .filter(crate::database::entities::route::Column::TripDayId.is_in(day_ids.clone()))
            .all(self.db.deref())
            .await?
            .into_iter()
            .map(|r| r.id)
            .collect();
        let mut location_pairs: Vec<(Uuid, Uuid)> = Vec::new();
        for day in &orphan_days {
            let locs = repositories::trip_day_locations::find_by_day(&self.db, day.id).await?;
            for l in locs {
                location_pairs.push((day.id, l.location_id));
            }
        }

        repositories::points_of_interest::unassign_all_for_days(&self.db, &day_ids).await?;
        repositories::routes::unassign_all_for_days(&self.db, &day_ids).await?;

        for day in orphan_days {
            repositories::trip_day_locations::delete_all_for_day(&self.db, day.id).await?;
            repositories::trip_days::delete_by_id(&self.db, day.id).await?;
            enqueue_trip_day_delete(&self.db, day.id).await?;
        }

        for poi_id in pois_to_unassign {
            enqueue_poi(&self.db, poi_id).await?;
        }
        for route_id in routes_to_unassign {
            enqueue_route(&self.db, route_id).await?;
        }
        for (day_id, location_id) in location_pairs {
            enqueue_trip_day_location_delete(&self.db, day_id, location_id).await?;
        }

        emit(DataChangeEvent::PoisChanged {
            trip_id: Some(trip_id),
        });
        emit(DataChangeEvent::RoutesChanged {
            trip_id: Some(trip_id),
        });
        emit(DataChangeEvent::TripDaysChanged { trip_id });
        Ok(())
    }

    async fn next_day_order(&self, day_id: Uuid) -> anyhow::Result<i32> {
        use sea_orm::{ColumnTrait, EntityTrait, QueryFilter, QueryOrder, QuerySelect};
        use std::ops::Deref;

        let poi_max = crate::database::entities::point_of_interest::Entity::find()
            .filter(crate::database::entities::point_of_interest::Column::TripDayId.eq(day_id))
            .order_by_desc(crate::database::entities::point_of_interest::Column::DayOrder)
            .limit(1)
            .one(self.db.deref())
            .await?
            .and_then(|p| p.day_order)
            .unwrap_or(-1);

        let route_max = crate::database::entities::route::Entity::find()
            .filter(crate::database::entities::route::Column::TripDayId.eq(day_id))
            .order_by_desc(crate::database::entities::route::Column::DayOrder)
            .limit(1)
            .one(self.db.deref())
            .await?
            .and_then(|r| r.day_order)
            .unwrap_or(-1);

        Ok(std::cmp::max(poi_max, route_max) + 1)
    }

    async fn day_has_items(&self, day_id: Uuid) -> anyhow::Result<bool> {
        use sea_orm::{ColumnTrait, EntityTrait, PaginatorTrait, QueryFilter};
        use std::ops::Deref;
        let poi_count = crate::database::entities::point_of_interest::Entity::find()
            .filter(crate::database::entities::point_of_interest::Column::TripDayId.eq(day_id))
            .count(self.db.deref())
            .await?;
        if poi_count > 0 {
            return Ok(true);
        }
        let route_count = crate::database::entities::route::Entity::find()
            .filter(crate::database::entities::route::Column::TripDayId.eq(day_id))
            .count(self.db.deref())
            .await?;
        Ok(route_count > 0)
    }

    async fn load_weather_by_location(
        &self,
        trip_id: Uuid,
    ) -> anyhow::Result<HashMap<(Uuid, NaiveDate), DayWeather>> {
        let locations = repositories::locations::find_all_by_trip(&self.db, trip_id).await?;
        let forecasts =
            repositories::weather_forecasts::load_forecasts_for_locations(&self.db, &locations).await?;

        let mut map = HashMap::new();
        for (location, (daily, _hourly)) in locations.iter().zip(forecasts.into_iter()) {
            for day in daily {
                map.insert(
                    (location.id, to_local_date(day.day)),
                    DayWeather {
                        location_id: location.id,
                        min_temperature: day.min_temperature,
                        max_temperature: day.max_temperature,
                        condition: day.condition.into(),
                        precipitation_amount: day.precipitation_amount,
                        precipitation_probability: day.precipitation_probability,
                    },
                );
            }
        }
        Ok(map)
    }

    async fn load_weather_by_accommodation(
        &self,
        trip_id: Uuid,
    ) -> anyhow::Result<HashMap<(Uuid, NaiveDate), DayWeather>> {
        let accommodations =
            repositories::accommodations::find_all_by_trip(&self.db, trip_id).await?;
        let forecasts = repositories::weather_forecasts::load_forecasts_for_accommodations(
            &self.db,
            &accommodations,
        )
        .await?;

        let mut map = HashMap::new();
        for (accommodation, (daily, _hourly)) in accommodations.iter().zip(forecasts.into_iter()) {
            for day in daily {
                map.insert(
                    (accommodation.id, to_local_date(day.day)),
                    DayWeather {
                        location_id: accommodation.id,
                        min_temperature: day.min_temperature,
                        max_temperature: day.max_temperature,
                        condition: day.condition.into(),
                        precipitation_amount: day.precipitation_amount,
                        precipitation_probability: day.precipitation_probability,
                    },
                );
            }
        }
        Ok(map)
    }
}

impl DayItem {
    fn day_order(&self) -> Option<i32> {
        match &self.details {
            DayItemDetails::PointOfInterest { day_order, .. } => Some(*day_order),
            DayItemDetails::Route { day_order, .. } => Some(*day_order),
            _ => None,
        }
    }
}

fn date_to_datetime(date: NaiveDate) -> DateTime<Utc> {
    Utc.from_utc_datetime(&date.and_hms_opt(0, 0, 0).expect("midnight always valid"))
}

fn to_local_date(dt: DateTime<Utc>) -> NaiveDate {
    Local.from_utc_datetime(&dt.naive_utc()).date_naive()
}


async fn enqueue_trip_day(db: &Database, day_id: Uuid) -> anyhow::Result<()> {
    if sync::session::current_user().await.is_none() {
        return Ok(());
    }
    let Some(model) = repositories::trip_days::find_by_id(db, day_id).await? else {
        return Ok(());
    };
    let row = sync::wire::TripDayRow::from_model(&model);
    sync::push::enqueue_if_signed_in(db, "trip_days", day_id, MutationOperation::Insert, &row).await
}

async fn enqueue_trip_day_delete(db: &Database, day_id: Uuid) -> anyhow::Result<()> {
    if sync::session::current_user().await.is_none() {
        return Ok(());
    }
    sync::push::enqueue_if_signed_in(
        db,
        "trip_days",
        day_id,
        MutationOperation::Delete,
        &serde_json::json!({ "id": day_id }),
    )
    .await
}

async fn enqueue_trip_day_location(
    db: &Database,
    day_id: Uuid,
    location_id: Uuid,
) -> anyhow::Result<()> {
    if sync::session::current_user().await.is_none() {
        return Ok(());
    }
    use sea_orm::{ColumnTrait, EntityTrait, QueryFilter};
    use std::ops::Deref;
    let Some(model) = crate::database::entities::trip_day_location::Entity::find()
        .filter(crate::database::entities::trip_day_location::Column::TripDayId.eq(day_id))
        .filter(crate::database::entities::trip_day_location::Column::LocationId.eq(location_id))
        .one(db.deref())
        .await?
    else {
        return Ok(());
    };
    let row = sync::wire::TripDayLocationRow::from_model(&model);
    // Composite-PK row — use location_id as the entity_id slot for
    // queue uniqueness; the payload carries both ids.
    sync::push::enqueue_if_signed_in(
        db,
        "trip_day_locations",
        location_id,
        MutationOperation::Insert,
        &row,
    )
    .await
}

async fn enqueue_trip_day_location_delete(
    db: &Database,
    day_id: Uuid,
    location_id: Uuid,
) -> anyhow::Result<()> {
    if sync::session::current_user().await.is_none() {
        return Ok(());
    }
    sync::push::enqueue_if_signed_in(
        db,
        "trip_day_locations",
        location_id,
        MutationOperation::Delete,
        &serde_json::json!({
            "trip_day_id": day_id,
            "location_id": location_id,
        }),
    )
    .await
}

async fn enqueue_poi(db: &Database, id: Uuid) -> anyhow::Result<()> {
    if sync::session::current_user().await.is_none() {
        return Ok(());
    }
    let Some(model) = repositories::points_of_interest::find_by_id(db, id).await? else {
        return Ok(());
    };
    let row = sync::wire::PointOfInterestRow::from_model(&model);
    sync::push::enqueue_if_signed_in(
        db,
        "points_of_interest",
        id,
        MutationOperation::Update,
        &row,
    )
    .await
}

async fn enqueue_route(db: &Database, id: Uuid) -> anyhow::Result<()> {
    if sync::session::current_user().await.is_none() {
        return Ok(());
    }
    let Some(model) = repositories::routes::find_by_id(db, id).await? else {
        return Ok(());
    };
    let row = sync::wire::RouteRow::from_model(&model);
    sync::push::enqueue_if_signed_in(db, "routes", id, MutationOperation::Update, &row).await
}
