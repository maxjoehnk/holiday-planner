use std::ops::Deref;
use sea_orm::ActiveValue::Set;
use sha2::{Digest, Sha256};
use uuid::Uuid;
use chrono::{DateTime, Local, NaiveDate, NaiveTime, TimeZone, Utc};
use crate::database::entities::pending_mutation::MutationOperation;
use crate::database::{Database, repositories, entities};
use crate::models::*;
use crate::commands::*;
use crate::handlers::{enqueue_trip_tag, Handler, LocationHandler, TripDayHandler};
use crate::sync;
use crate::third_party::unsplash;

fn sha256_hex(bytes: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(bytes);
    format!("{:x}", hasher.finalize())
}

pub struct TripHandler {
    db: Database,
}

impl Handler for TripHandler {
    fn create(db: Database) -> Self {
        Self {
            db,
        }
    }
}

impl TripHandler {
    fn determine_accommodation_status(&self, accommodations: &[entities::accommodation::Model], now: DateTime<Utc>) -> Option<AccommodationStatus> {
        for accommodation in accommodations {
            if let (Some(check_in), Some(check_out)) = (accommodation.check_in, accommodation.check_out) {
                if now >= check_in && now < check_out {
                    return Some(AccommodationStatus {
                        accommodation_name: accommodation.name.clone(),
                        status_type: AccommodationStatusType::CheckOut,
                        datetime: check_out,
                    });
                }
                else if now < check_in {
                    return Some(AccommodationStatus {
                        accommodation_name: accommodation.name.clone(),
                        status_type: AccommodationStatusType::CheckIn,
                        datetime: check_in,
                    });
                }
            }
        }
        None
    }
    pub async fn get_trips(&self) -> anyhow::Result<Vec<TripListModel>> {
        tracing::debug!("Getting trips");
        let trips = repositories::trips::find_all(&self.db).await?;

        let trips = trips.into_iter()
            .map(|trip| TripListModel {
                id: trip.id,
                name: trip.name,
                start_date: trip.start_date,
                end_date: trip.end_date,
                header_image: trip.header_image,
                owner_id: trip
                    .owner_id
                    .as_deref()
                    .and_then(|s| Uuid::parse_str(s).ok()),
                is_detached: trip.detached_at.is_some(),
            })
            .collect();

        Ok(trips)
    }

    pub async fn get_upcoming_trips(&self) -> anyhow::Result<Vec<TripListModel>> {
        tracing::debug!("Getting upcoming trips");
        let trips = repositories::trips::find_all(&self.db).await?;
        let now = Local::now().date_naive();

        let trips = trips.into_iter()
            .filter(|trip| trip.end_date.to_local_date() >= now)
            .map(|trip| TripListModel {
                id: trip.id,
                name: trip.name,
                start_date: trip.start_date,
                end_date: trip.end_date,
                header_image: trip.header_image,
                owner_id: trip
                    .owner_id
                    .as_deref()
                    .and_then(|s| Uuid::parse_str(s).ok()),
                is_detached: trip.detached_at.is_some(),
            })
            .collect();

        Ok(trips)
    }

    pub async fn get_past_trips(&self) -> anyhow::Result<Vec<TripListModel>> {
        tracing::debug!("Getting past trips");
        let trips = repositories::trips::find_all(&self.db).await?;
        let now = Local::now().date_naive();

        let trips = trips.into_iter()
            .filter(|trip| trip.end_date.to_local_date() < now)
            .map(|trip| TripListModel {
                id: trip.id,
                name: trip.name,
                start_date: trip.start_date,
                end_date: trip.end_date,
                header_image: trip.header_image,
                owner_id: trip
                    .owner_id
                    .as_deref()
                    .and_then(|s| Uuid::parse_str(s).ok()),
                is_detached: trip.detached_at.is_some(),
            })
            .collect();

        Ok(trips)
    }

    pub async fn get_trip_overview(&self, id: Uuid) -> anyhow::Result<TripOverviewModel> {
        let trip = repositories::trips::find_by_id(&self.db, id).await?;

        let Some(trip) = trip else {
            anyhow::bail!("Trip not found");
        };

        let total_packing_list_items = repositories::trip_packing_list_entries::count_by_trip(&self.db, id).await?;
        let pending_packing_list_items = repositories::trip_packing_list_entries::count_pending_by_trip(&self.db, id).await?;

        let points_of_interest_count = repositories::points_of_interest::count_by_trip(self.db.deref(), id).await?;
        let routes_count = repositories::routes::count_by_trip(self.db.deref(), id).await?;
        let activities_count = (points_of_interest_count + routes_count) as usize;
        let bookings_count = repositories::bookings::count_all_bookings_by_trip(self.db.deref(), id).await? as usize;

        let accommodations = repositories::accommodations::find_all_by_trip(&self.db, id).await?;
        let now = Utc::now();
        let accommodation_status = self.determine_accommodation_status(&accommodations, now);
        
        let locations = repositories::locations::find_all_by_trip(&self.db, id).await?;
        let locations_list = locations.iter()
            .map(|location| TripLocationSummary {
                city: location.city.clone(),
                country: location.country.clone(),
            })
            .collect();

        // If there's exactly one location, fetch detailed weather/tidal data
        let single_location_weather_tidal = if locations.len() == 1 {
            let location_handler = LocationHandler::create(self.db.clone());
            let detailed_locations = location_handler.get_trip_locations(id).await?;
            detailed_locations.into_iter().next()
        } else {
            None
        };
        let duration_days = ((trip.end_date.with_time(NaiveTime::default()).earliest().unwrap()) - (trip.start_date.with_time(NaiveTime::default()).earliest().unwrap())).num_days() + 1;

        let next_trains = repositories::transits::find_upcoming_trains(&self.db, id).await?;
        let next_transit = match next_trains.as_slice() {
            [] => None,
            [train] if train.scheduled_departure_time < now => {
                let train = train.clone();
                Some(TransitOverviewModel::ArrivingTrain(TrainOverviewModel {
                    train_number: train.train_number,
                    station: train.arrival_station_name,
                    platform: train.arrival_scheduled_platform,
                    time: train.scheduled_arrival_time,
                }))
            },
            [train] => {
                let train = train.clone();
                Some(TransitOverviewModel::DepartingTrain(TrainOverviewModel {
                    train_number: train.train_number,
                    station: train.departure_station_name,
                    platform: train.departure_scheduled_platform,
                    time: train.scheduled_departure_time,
                }))
            },
            trains => Some(TransitOverviewModel::UpcomingTransits(trains.len())),
        };

        let owner_id = trip
            .owner_id
            .as_deref()
            .and_then(|s| Uuid::parse_str(s).ok());
        let is_detached = trip.detached_at.is_some();
        let trip = TripOverviewModel {
            id: trip.id,
            name: trip.name,
            start_date: trip.start_date,
            end_date: trip.end_date,
            duration_days,
            header_image: trip.header_image,
            next_transit,
            pending_packing_list_items,
            total_packing_list_items,
            activities_count,
            bookings_count,
            accommodation_status,
            locations_list,
            single_location_weather_tidal,
            owner_id,
            is_detached,
        };

        Ok(trip)
    }

    pub async fn create_trip(&self, command: CreateTrip) -> anyhow::Result<TripOverviewModel> {
        let current_user = sync::session::current_user().await;
        // Generate the trip id up front so we can mint a Storage path
        // for the header image in the same active model rather than
        // doing a follow-up UPDATE just to attach the path.
        let trip_id = Uuid::new_v4();
        let (header_path, header_sha) = match command.header_image.as_deref() {
            Some(bytes) => (
                Some(sync::wire::trip_header_storage_path(trip_id, Uuid::new_v4())),
                Some(sha256_hex(bytes)),
            ),
            None => (None, None),
        };
        let model = entities::trip::ActiveModel {
            id: Set(trip_id),
            name: Set(command.name),
            start_date: Set(command.start_date),
            end_date: Set(command.end_date),
            header_image: Set(command.header_image),
            header_image_path: Set(header_path),
            header_image_sha256: Set(header_sha),
            header_image_uploaded_at: Set(None),
            updated_at: Set(Utc::now()),
            last_modified_by: Set(current_user.map(|u| u.to_string())),
            owner_id: Set(current_user.map(|u| u.to_string())),
            ..Default::default()
        };
        let trip = repositories::trips::create(&self.db, model).await?;

        if let Some(user_id) = current_user {
            let row = sync::wire::TripRow::from_model(&trip, user_id);
            sync::push::enqueue(
                self.db.deref(),
                "trips",
                trip.id,
                MutationOperation::Insert,
                &row,
            )
            .await?;
        }

        if let Some(location) = command.location {
            let location_handler = LocationHandler::create(self.db.clone());
            location_handler.add_trip_location(trip.id, location).await?;
        }

        // Set trip tags
        for tag_id in command.tag_ids {
            repositories::tags::add_tag_to_trip(&self.db, trip.id, tag_id).await?;
            enqueue_trip_tag(&self.db, trip.id, tag_id, MutationOperation::Insert).await?;
        }

        let trip = self.get_trip_overview(trip.id).await?;

        Ok(trip)
    }

    pub async fn update_trip(&self, command: UpdateTrip) -> anyhow::Result<TripOverviewModel> {
        let Some(existing) = repositories::trips::find_by_id(&self.db, command.id).await? else {
            return Err(anyhow::anyhow!("Trip not found"));
        };

        let dates_changed =
            existing.start_date != command.start_date || existing.end_date != command.end_date;

        let current_user = sync::session::current_user().await;
        // Only mint a fresh Storage path when the bytes actually
        // changed. Hash-equality (or both-None) means we reuse the
        // existing path + uploaded_at and the push worker skips the
        // upload. Scrubbing the previous Storage object on path
        // change is handled by the `scrub_obsolete_header_image`
        // BEFORE UPDATE trigger on `public.trips`, so we don't need
        // to fire a storage_delete from here.
        let new_sha = command.header_image.as_deref().map(sha256_hex);
        let (header_path, header_sha, header_uploaded_at) =
            if new_sha == existing.header_image_sha256 {
                (
                    existing.header_image_path.clone(),
                    existing.header_image_sha256.clone(),
                    existing.header_image_uploaded_at,
                )
            } else {
                let path = command.header_image.as_ref().map(|_| {
                    sync::wire::trip_header_storage_path(command.id, Uuid::new_v4())
                });
                (path, new_sha, None)
            };
        let model = entities::trip::ActiveModel {
            id: Set(command.id),
            name: Set(command.name),
            start_date: Set(command.start_date),
            end_date: Set(command.end_date),
            header_image: Set(command.header_image),
            header_image_path: Set(header_path),
            header_image_sha256: Set(header_sha),
            header_image_uploaded_at: Set(header_uploaded_at),
            updated_at: Set(Utc::now()),
            last_modified_by: Set(current_user.map(|u| u.to_string())),
            ..Default::default()
        };
        repositories::trips::update(&self.db, model).await?;

        // Update trip tags. Snapshot the previous set so the queue can
        // carry tombstones for tags that drop out.
        let previous = repositories::tags::find_by_trip_id(&self.db, command.id).await?;
        for tag in previous {
            if !command.tag_ids.contains(&tag.id) {
                enqueue_trip_tag(&self.db, command.id, tag.id, MutationOperation::Delete).await?;
            }
        }
        repositories::tags::clear_trip_tags(&self.db, command.id).await?;
        for tag_id in command.tag_ids {
            repositories::tags::add_tag_to_trip(&self.db, command.id, tag_id).await?;
            enqueue_trip_tag(&self.db, command.id, tag_id, MutationOperation::Insert).await?;
        }

        if let Some(user_id) = current_user {
            // Refetch so the enqueued row carries the freshly bumped updated_at.
            if let Some(refreshed) = repositories::trips::find_by_id(&self.db, command.id).await? {
                let owner_id = refreshed
                    .owner_id
                    .as_deref()
                    .and_then(|s| Uuid::parse_str(s).ok())
                    .unwrap_or(user_id);
                let row = sync::wire::TripRow::from_model(&refreshed, owner_id);
                sync::push::enqueue(
                    self.db.deref(),
                    "trips",
                    refreshed.id,
                    MutationOperation::Update,
                    &row,
                )
                .await?;
            }
        }

        if dates_changed {
            let day_handler = TripDayHandler::create(self.db.clone());
            day_handler.reconcile_after_trip_date_change(command.id).await?;
        }

        let trip = self.get_trip_overview(command.id).await?;

        Ok(trip)
    }

    pub async fn delete_trip(&self, trip_id: Uuid) -> anyhow::Result<()> {
        let trip = repositories::trips::find_by_id(&self.db, trip_id).await?;
        let Some(trip) = trip else {
            anyhow::bail!("Trip not found");
        };

        if let Some(current_user) = sync::session::current_user().await {
            let is_owner = trip
                .owner_id
                .as_deref()
                .and_then(|s| Uuid::parse_str(s).ok())
                == Some(current_user);

            if is_owner {
                // Storage cleanup (the trip's header image + every
                // cascaded attachment's blob) is handled server-side
                // by the BEFORE DELETE triggers on `trips` and
                // `attachments`, so we just enqueue the hard-delete.
                sync::push::enqueue(
                    self.db.deref(),
                    "trips",
                    trip_id,
                    MutationOperation::Delete,
                    &serde_json::json!({
                        "id": trip_id,
                        "hard_delete": true,
                    }),
                )
                .await?;
            } else {
                // Non-owner: leave the trip rather than touching the
                // shared row. Push as a trip_members soft-delete so
                // the user's own membership row carries the tombstone.
                sync::push::enqueue(
                    self.db.deref(),
                    "trip_members",
                    current_user,
                    MutationOperation::Delete,
                    &serde_json::json!({
                        "trip_id": trip_id,
                        "user_id": current_user,
                    }),
                )
                .await?;
            }
        }

        repositories::trips::delete(&self.db, trip_id).await?;

        Ok(())
    }
    
    pub async fn search_web_images(&self, command: SearchWebImages) -> anyhow::Result<Vec<WebImage>> {
        tracing::debug!("Searching web images for query: {}", command.query);
        
        let unsplash_images = unsplash::search_images(&command.query).await?;
        
        let images = unsplash_images.into_iter()
            .map(|image| WebImage {
                id: image.id,
                url: image.urls.regular,
                thumbnail_url: image.urls.thumb,
                author: image.user.name,
                description: image.description.or(image.alt_description),
            })
            .collect();
        
        Ok(images)
    }
    
    pub async fn download_web_image(&self, image_url: String) -> anyhow::Result<Vec<u8>> {
        tracing::debug!("Downloading web image from URL: {}", image_url);
        
        let image_bytes = unsplash::download_image(&image_url).await?;
        
        Ok(image_bytes)
    }
}

trait DateExt {
    fn to_local_date(&self) -> NaiveDate;
}

impl DateExt for DateTime<Utc> {
    fn to_local_date(&self) -> NaiveDate {
        Local.from_utc_datetime(&self.naive_utc()).date_naive()
    }
}
