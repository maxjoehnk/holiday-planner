use sea_orm::ActiveValue::Set;
use sea_orm::IntoActiveModel;
use uuid::Uuid;
use crate::commands::{AddReservation, AddCarRental, UpdateReservation, UpdateCarRental};
use crate::database::{Database, entities, repositories};
use crate::handlers::Handler;
use crate::models::*;

pub struct BookingHandler {
    db: Database,
}

impl Handler for BookingHandler {
    fn create(db: Database) -> Self {
        Self {
            db,
        }
    }
}

impl BookingHandler {
    pub async fn add_reservation(&self, command: AddReservation) -> anyhow::Result<()> {
        tracing::debug!("Adding reservation to trip {}", command.trip_id);
        
        let reservation = entities::reservation::ActiveModel {
            id: Set(Uuid::new_v4()),
            trip_id: Set(command.trip_id),
            title: Set(command.title),
            address: Set(command.address),
            start_date: Set(command.start_date),
            end_date: Set(command.end_date),
            link: Set(command.link),
            booking_number: Set(command.booking_number),
            category: Set(command.category.into()),
        };
        
        repositories::bookings::insert_reservation(&self.db, reservation).await?;

        Ok(())
    }
    
    pub async fn get_trip_reservations(&self, trip_id: Uuid) -> anyhow::Result<Vec<Reservation>> {
        let reservations = repositories::bookings::find_all_reservations_by_trip(&self.db, trip_id).await?;
        let reservations = reservations.into_iter().map(|r| Reservation {
            id: r.id,
            title: r.title,
            address: r.address,
            start_date: r.start_date,
            end_date: r.end_date,
            link: r.link,
            booking_number: r.booking_number,
            category: r.category.into(),
            attachments: vec![], // TODO: Load attachments if needed
        }).collect();
        
        Ok(reservations)
    }

    pub async fn update_reservation(&self, command: UpdateReservation) -> anyhow::Result<()> {
        let Some(reservation) = repositories::bookings::find_reservation_by_id(&self.db, command.id).await? else {
            anyhow::bail!("Unknown reservation");
        };
        let mut reservation = reservation.into_active_model();
        reservation.title.set_if_not_equals(command.title);
        reservation.address.set_if_not_equals(command.address);
        reservation.start_date.set_if_not_equals(command.start_date);
        reservation.end_date.set_if_not_equals(command.end_date);
        reservation.link.set_if_not_equals(command.link);
        reservation.booking_number.set_if_not_equals(command.booking_number);
        reservation.category.set_if_not_equals(command.category.into());

        repositories::bookings::update_reservation(&self.db, reservation).await?;

        Ok(())
    }

    pub async fn delete_reservation(&self, reservation_id: Uuid) -> anyhow::Result<()> {
        repositories::bookings::delete_reservation_by_id(&self.db, reservation_id).await?;

        Ok(())
    }

    pub async fn add_car_rental(&self, command: AddCarRental) -> anyhow::Result<()> {
        tracing::debug!("Adding car rental to trip {}", command.trip_id);
        
        let car_rental = entities::car_rental::ActiveModel {
            id: Set(Uuid::new_v4()),
            trip_id: Set(command.trip_id),
            provider: Set(command.provider),
            pick_up_date: Set(command.pick_up_date),
            pick_up_location: Set(command.pick_up_location),
            return_date: Set(command.return_date),
            return_location: Set(command.return_location),
            booking_number: Set(command.booking_number),
        };
        
        repositories::bookings::insert_car_rental(&self.db, car_rental).await?;

        Ok(())
    }
    
    pub async fn get_trip_car_rentals(&self, trip_id: Uuid) -> anyhow::Result<Vec<CarRental>> {
        let car_rentals = repositories::bookings::find_all_car_rentals_by_trip(&self.db, trip_id).await?;
        let car_rentals = car_rentals.into_iter().map(|c| CarRental {
            id: c.id,
            provider: c.provider,
            pick_up_date: c.pick_up_date,
            pick_up_location: c.pick_up_location,
            return_date: c.return_date,
            return_location: c.return_location,
            booking_number: c.booking_number,
            attachments: vec![], // TODO: Load attachments if needed
        }).collect();
        
        Ok(car_rentals)
    }

    pub async fn update_car_rental(&self, command: UpdateCarRental) -> anyhow::Result<()> {
        let Some(car_rental) = repositories::bookings::find_car_rental_by_id(&self.db, command.id).await? else {
            anyhow::bail!("Unknown car rental");
        };
        let mut car_rental = car_rental.into_active_model();
        car_rental.provider.set_if_not_equals(command.provider);
        car_rental.pick_up_date.set_if_not_equals(command.pick_up_date);
        car_rental.pick_up_location.set_if_not_equals(command.pick_up_location);
        car_rental.return_date.set_if_not_equals(command.return_date);
        car_rental.return_location.set_if_not_equals(command.return_location);
        car_rental.booking_number.set_if_not_equals(command.booking_number);

        repositories::bookings::update_car_rental(&self.db, car_rental).await?;

        Ok(())
    }

    pub async fn delete_car_rental(&self, car_rental_id: Uuid) -> anyhow::Result<()> {
        repositories::bookings::delete_car_rental_by_id(&self.db, car_rental_id).await?;

        Ok(())
    }

    pub async fn get_trip_bookings(&self, trip_id: Uuid) -> anyhow::Result<Vec<Booking>> {
        let reservations = self.get_trip_reservations(trip_id).await?;
        let car_rentals = self.get_trip_car_rentals(trip_id).await?;

        let mut bookings: Vec<Booking> = Vec::new();
        
        for reservation in reservations {
            bookings.push(Booking::Reservation(reservation));
        }
        
        for car_rental in car_rentals {
            bookings.push(Booking::CarRental(car_rental));
        }

        bookings.sort_by(|a, b| {
            let date_a = match a {
                Booking::Reservation(r) => r.start_date,
                Booking::CarRental(c) => c.pick_up_date,
            };
            let date_b = match b {
                Booking::Reservation(r) => r.start_date,
                Booking::CarRental(c) => c.pick_up_date,
            };
            date_a.cmp(&date_b)
        });

        Ok(bookings)
    }
}
