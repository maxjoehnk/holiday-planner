create table car_rentals
(
    id blob not null constraint car_rentals_pk primary key,
    trip_id blob not null constraint car_rentals_trip_id_fk references trips on delete cascade,
    provider text not null,
    pick_up_date text not null,
    pick_up_location text not null,
    return_date text not null,
    return_location text,
    booking_number text
);

create table reservations
(
    id blob not null constraint reservations_pk primary key,
    trip_id blob not null constraint reservations_trip_id_fk references trips on delete cascade,
    title text not null,
    address text,
    start_date text not null,
    end_date text,
    link text,
    booking_number text
);
