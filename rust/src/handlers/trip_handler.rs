use std::ops::Deref;
use sea_orm::ActiveValue::Set;
use uuid::Uuid;
use chrono::{DateTime, Local, NaiveDate, NaiveTime, TimeZone, Utc};
use crate::database::{Database, repositories, entities};
use crate::models::*;
use crate::commands::*;
use crate::handlers::{Handler, TripPackingListHandler};
use crate::third_party::unsplash;

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
            })
            .collect();

        Ok(trips)
    }

    pub async fn get_trip_overview(&self, id: Uuid) -> anyhow::Result<TripOverviewModel> {
        let trip = repositories::trips::find_by_id(&self.db, id).await?;

        let Some(trip) = trip else {
            anyhow::bail!("Trip not found");
        };

        // TODO: we should not depend upon another handler
        // Also we don't need to fetch all the packing list items for the overview
        let trip_packing_list_handler = TripPackingListHandler::create(self.db.clone());
        let packing_items = trip_packing_list_handler.get_trip_packing_list(id).await?;
        let pending_packing_list_items = packing_items.entries.iter().filter(|entry| !entry.is_packed).count();
        let packed_packing_list_items = packing_items.entries.iter().filter(|entry| entry.is_packed).count();
        let total_packing_list_items = packing_items.entries.len();
        
        let points_of_interest_count = repositories::points_of_interest::count_by_trip(self.db.deref(), id).await? as usize;
        let bookings_count = repositories::bookings::count_all_bookings_by_trip(self.db.deref(), id).await? as usize;

        let accommodations = repositories::accommodations::find_all_by_trip(&self.db, id).await?;
        let now = Utc::now();
        let accommodation_status = self.determine_accommodation_status(&accommodations, now);
        
        let locations = repositories::locations::find_all_by_trip(&self.db, id).await?;
        let locations_list = locations.into_iter()
            .map(|location| TripLocationSummary {
                city: location.city,
                country: location.country,
            })
            .collect();

        let duration_days = ((trip.end_date.with_time(NaiveTime::default()).earliest().unwrap()) - (trip.start_date.with_time(NaiveTime::default()).earliest().unwrap())).num_days() + 1;
        let trip = TripOverviewModel {
            id: trip.id,
            name: trip.name,
            start_date: trip.start_date,
            end_date: trip.end_date,
            duration_days,
            header_image: trip.header_image,
            pending_packing_list_items,
            total_packing_list_items,
            packed_packing_list_items,
            points_of_interest_count,
            bookings_count,
            accommodation_status,
            locations_list,
        };

        Ok(trip)
    }

    pub async fn create_trip(&self, command: CreateTrip) -> anyhow::Result<TripOverviewModel> {
        let model = entities::trip::ActiveModel {
            name: Set(command.name),
            start_date: Set(command.start_date),
            end_date: Set(command.end_date),
            header_image: Set(command.header_image),
            ..Default::default()
        };
        let trip = repositories::trips::create(&self.db, model).await?;
        let trip = self.get_trip_overview(trip.id).await?;

        Ok(trip)
    }

    pub async fn update_trip(&self, command: UpdateTrip) -> anyhow::Result<TripOverviewModel> {
        let trip = repositories::trips::find_by_id(&self.db, command.id).await?;
        if trip.is_none() {
            return Err(anyhow::anyhow!("Trip not found"));
        }

        let model = entities::trip::ActiveModel {
            id: Set(command.id),
            name: Set(command.name),
            start_date: Set(command.start_date),
            end_date: Set(command.end_date),
            header_image: Set(command.header_image),
        };
        repositories::trips::update(&self.db, model).await?;
        
        let trip = self.get_trip_overview(command.id).await?;
        
        Ok(trip)
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
