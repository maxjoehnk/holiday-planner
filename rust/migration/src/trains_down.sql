create table transits_trains
(
    id                           blob not null
        constraint transits_trains_pk
            primary key,
    departure_station            text,
    departure_scheduled_platform text,
    departure_actual_platform    text,
    departure_city               text,
    departure_country            integer,
    arrival_station              text,
    arrival_scheduled_platform   text,
    arrival_actual_platform      text,
    arrival_city                 text,
    arrival_country              text
);

create table transits
(
    id       blob not null
        constraint transits_pk
            primary key,
    name     text,
    trip_id  blob not null
        constraint transits_trips_id_fk
            references trips
            on delete cascade,
    train_id blob
        constraint transits_transits_trains_id_fk
            references transits_trains
            on delete cascade
);

drop table trains;
