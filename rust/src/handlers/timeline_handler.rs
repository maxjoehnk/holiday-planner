use uuid::Uuid;
use crate::database::{Database, repositories};
use crate::handlers::Handler;
use crate::models::timeline::{TimelineModel, TimelineItemDetails, TimelineItem};

pub struct TimelineHandler {
    db: Database,
}

impl Handler for TimelineHandler {
    fn create(db: Database) -> Self {
        Self {
            db
        }
    }
}

impl TimelineHandler {
    pub async fn get_timeline(&self, trip_id: Uuid) -> anyhow::Result<TimelineModel> {
        let car_rentals = repositories::bookings::find_all_car_rentals_by_trip(&self.db, trip_id).await?;
        let reservations = repositories::bookings::find_all_reservations_by_trip(&self.db, trip_id).await?;
        let accommodations = repositories::accommodations::find_all_by_trip(&self.db, trip_id).await?;

        let car_rentals = car_rentals.into_iter().flat_map(|rental| [TimelineItem {
            date: rental.pick_up_date,
            details: TimelineItemDetails::CarRentalPickUp {
                address: rental.pick_up_location.clone(),
                provider: rental.provider.clone(),
            }
        }, TimelineItem {
            date: rental.return_date,
            details: TimelineItemDetails::CarRentalDropOff {
                address: rental.return_location.unwrap_or(rental.pick_up_location),
                provider: rental.provider,
            }
        }]);
        let reservations = reservations.into_iter().map(|reservation| TimelineItem {
            date: reservation.start_date,
            details: TimelineItemDetails::Reservation {
                title: reservation.title,
                address: reservation.address,
                category: reservation.category.into(),
            }
        });
        let check_ins = accommodations.iter().filter_map(|accommodation| Some(TimelineItem {
            date: accommodation.check_in?,
            details: TimelineItemDetails::CheckIn {
                address: accommodation.address.clone(),
            }
        }));
        let check_outs = accommodations.iter().filter_map(|accommodation| Some(TimelineItem {
            date: accommodation.check_out?,
            details: TimelineItemDetails::CheckOut {
                address: accommodation.address.clone(),
            }
        }));

        let mut timeline_items: Vec<TimelineItem> = car_rentals
            .into_iter()
            .chain(reservations)
            .chain(check_ins)
            .chain(check_outs)
            .collect();
        timeline_items.sort_by_key(|item| item.date);

        let now = chrono::Utc::now();

        let (past, future) = timeline_items.into_iter().partition(|item| item.date <= now);

        Ok(TimelineModel { future, past })
    }
}
