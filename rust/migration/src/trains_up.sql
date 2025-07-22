create table trains
(
    id blob not null constraint trains_pk primary key,
    trip_id blob not null constraint trains_trip_id_fk references trips on delete cascade,
    train_number text,
    departure_station_name text not null,
    departure_station_city text,
    departure_station_country text,
    departure_scheduled_platform text not null,
    arrival_station_name text not null,
    arrival_station_city text,
    arrival_station_country text,
    arrival_scheduled_platform text not null,
    scheduled_departure_time text not null,
    scheduled_arrival_time text not null
);

drop table transits;
drop table transits_trains;
