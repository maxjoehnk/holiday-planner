create table packing_list_groups
(
    id   blob not null
        constraint packing_list_groups_pk
            primary key,
    name text not null
);

create table packing_list_entries
(
    id                 blob not null
        constraint packing_list_pk
            primary key,
    name               text not null,
    description        text,
    quantity_per_day   integer,
    quantity_per_night integer,
    quantity_fixed     integer,
    group_id           blob
        constraint packing_list_packing_list_groups_id_fk
            references packing_list_groups
            on delete set null
);

create table tags
(
    id   blob not null
        constraint tags_pk
            primary key,
    name text not null
);

create table packing_list_conditions
(
    id                      blob not null
        constraint packing_list_conditions_pk
            primary key,
    packing_list_entry_id   blob not null
        constraint packing_list_conditions_packing_list_entries_id_fk
            references packing_list_entries
            on delete cascade,
    min_trip_duration       integer,
    max_trip_duration       integer,
    min_temperature         real,
    max_temperature         real,
    weather_condition       integer,
    weather_min_probability real,
    tag                     blob
        constraint packing_list_conditions_tags_id_fk
            references tags
            on delete cascade,
    constraint check_only_single_condition
        check ((packing_list_conditions.min_trip_duration is not null
            and packing_list_conditions.max_trip_duration is null
            and packing_list_conditions.max_temperature is null
            and packing_list_conditions.min_temperature is null
            and packing_list_conditions.tag is null
            and packing_list_conditions.weather_condition is null
            and packing_list_conditions.weather_min_probability is null) or
               (packing_list_conditions.max_trip_duration is not null
                   and packing_list_conditions.min_trip_duration is null
                   and packing_list_conditions.max_temperature is null
                   and packing_list_conditions.min_temperature is null
                   and packing_list_conditions.tag is null
                   and packing_list_conditions.weather_condition is null
                   and packing_list_conditions.weather_min_probability is null) or
               (packing_list_conditions.min_temperature is not null
                   and packing_list_conditions.min_trip_duration is null
                   and packing_list_conditions.max_trip_duration is null
                   and packing_list_conditions.max_temperature is null
                   and packing_list_conditions.tag is null
                   and packing_list_conditions.weather_condition is null
                   and packing_list_conditions.weather_min_probability is null) or
               (packing_list_conditions.max_temperature is not null
                   and packing_list_conditions.min_trip_duration is null
                   and packing_list_conditions.max_trip_duration is null
                   and packing_list_conditions.min_temperature is null
                   and packing_list_conditions.tag is null
                   and packing_list_conditions.weather_condition is null
                   and packing_list_conditions.weather_min_probability is null) or
               (packing_list_conditions.tag is not null
                   and packing_list_conditions.min_trip_duration is null
                   and packing_list_conditions.max_trip_duration is null
                   and packing_list_conditions.min_temperature is null
                   and packing_list_conditions.max_temperature is null
                   and packing_list_conditions.weather_condition is null
                   and packing_list_conditions.weather_min_probability is null) or
               (packing_list_conditions.weather_condition is not null
                   and packing_list_conditions.weather_min_probability is not null
                   and packing_list_conditions.min_trip_duration is null
                   and packing_list_conditions.max_trip_duration is null
                   and packing_list_conditions.min_temperature is null
                   and packing_list_conditions.max_temperature is null
                   and packing_list_conditions.tag is null))
);

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

create table trips
(
    id           blob    not null
        constraint trips_pk
            primary key,
    name         text    not null,
    start_date   integer not null,
    end_date     integer not null,
    header_image blob
);

create table accommodations
(
    id        blob not null
        constraint accommodations_pk
            primary key,
    name      text not null,
    check_in  integer,
    check_out integer,
    address   text,
    trip_id   blob not null
        constraint accommodations_trips_id_fk
            references trips
            on delete cascade
);

create table attachments
(
    id           blob not null
        constraint attachments_pk
            primary key,
    name         TEXT not null,
    trip_id      blob not null
        constraint attachments_trips_id_fk
            references trips
            on delete cascade,
    data         blob not null,
    file_name    text not null,
    content_type text not null
);

create table accommodation_attachments
(
    accommodation_id blob not null
        constraint accommodation_attachments_accommodations_id_fk
            references accommodations
            on delete cascade,
    attachment_id    blob not null
        constraint accommodation_attachments_attachments_id_fk
            references attachments
            on delete cascade,
    constraint accommodation_attachments_pk
        primary key (accommodation_id, attachment_id)
);

create table location
(
    id                    blob not null
        constraint location_pk
            primary key,
    coordinates_latitude  real not null,
    coordinates_longitude real not null,
    city                  text,
    country               text,
    trip_id               blob not null
        constraint location_trips_id_fk
            references trips
            on delete cascade
);

create table location_attachments
(
    location_id   blob not null
        constraint location_attachments_location_id_fk
            references locations
            on delete cascade,
    attachment_id blob not null
        constraint location_attachments_attachments_id_fk
            references attachments
            on delete cascade,
    constraint location_attachments_pk
        primary key (location_id, attachment_id)
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

create table trip_packing_list_entry
(
    trip_id               blob          not null
        constraint trip_packing_list_entry_trips_id_fk
            references trips
            on delete cascade,
    packing_list_entry_id blob          not null
        constraint trip_packing_list_entry_packing_list_entries_id_fk
            references packing_list_entries
            on delete cascade,
    is_packed             int default 0 not null,
    override_quantity     integer,
    constraint trip_packing_list_entry_pk
        primary key (packing_list_entry_id, trip_id)
);

create table trip_tags
(
    trip_id blob not null
        constraint trip_tags_trips_id_fk
            references trips
            on delete cascade,
    tag_id  blob not null
        constraint trip_tags_tags_id_fk
            references tags
            on delete cascade,
    constraint trip_tags_pk
        primary key (trip_id, tag_id)
);

