PRAGMA foreign_keys = OFF;

ALTER TABLE locations ADD COLUMN pollen_information_last_updated DATETIME;
ALTER TABLE accommodations ADD COLUMN pollen_information_last_updated DATETIME;

CREATE TABLE pollen_forecast
(
    id               blob not null
        constraint pollen_forecast_pk
            primary key,
    location_id      blob
        constraint pollen_forecast_location_id_fk
            references locations
            on delete cascade,
    accommodation_id blob
        constraint pollen_forecast_accommodation_id_fk
            references accommodations
            on delete cascade,
    constraint pollen_forecast_owner_xor
        check ((location_id is not null and accommodation_id is null)
            or (location_id is null and accommodation_id is not null))
);

CREATE TABLE pollen_daily_forecast
(
    id           blob    not null
        constraint pollen_daily_forecast_pk
            primary key,
    forecast_id  blob    not null
        constraint pollen_daily_forecast_forecast_id_fk
            references pollen_forecast
            on delete cascade,
    day          datetime not null,
    pollen_type  integer not null,
    index_value  integer not null,
    category     text
);

CREATE UNIQUE INDEX pollen_daily_forecast_forecast_day_type_idx
    ON pollen_daily_forecast (forecast_id, day, pollen_type);

CREATE TABLE packing_list_conditions_new
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
    pollen_type             integer,
    min_pollen_index        integer,
    constraint check_only_single_condition
        check ((min_trip_duration is not null
            and max_trip_duration is null
            and max_temperature is null
            and min_temperature is null
            and tag is null
            and weather_condition is null
            and weather_min_probability is null
            and pollen_type is null
            and min_pollen_index is null) or
               (max_trip_duration is not null
                   and min_trip_duration is null
                   and max_temperature is null
                   and min_temperature is null
                   and tag is null
                   and weather_condition is null
                   and weather_min_probability is null
                   and pollen_type is null
                   and min_pollen_index is null) or
               (min_temperature is not null
                   and min_trip_duration is null
                   and max_trip_duration is null
                   and max_temperature is null
                   and tag is null
                   and weather_condition is null
                   and weather_min_probability is null
                   and pollen_type is null
                   and min_pollen_index is null) or
               (max_temperature is not null
                   and min_trip_duration is null
                   and max_trip_duration is null
                   and min_temperature is null
                   and tag is null
                   and weather_condition is null
                   and weather_min_probability is null
                   and pollen_type is null
                   and min_pollen_index is null) or
               (tag is not null
                   and min_trip_duration is null
                   and max_trip_duration is null
                   and min_temperature is null
                   and max_temperature is null
                   and weather_condition is null
                   and weather_min_probability is null
                   and pollen_type is null
                   and min_pollen_index is null) or
               (weather_condition is not null
                   and weather_min_probability is not null
                   and min_trip_duration is null
                   and max_trip_duration is null
                   and min_temperature is null
                   and max_temperature is null
                   and tag is null
                   and pollen_type is null
                   and min_pollen_index is null) or
               (pollen_type is not null
                   and min_pollen_index is not null
                   and min_trip_duration is null
                   and max_trip_duration is null
                   and min_temperature is null
                   and max_temperature is null
                   and tag is null
                   and weather_condition is null
                   and weather_min_probability is null))
);

INSERT INTO packing_list_conditions_new (id, packing_list_entry_id, min_trip_duration, max_trip_duration, min_temperature, max_temperature, weather_condition, weather_min_probability, tag, pollen_type, min_pollen_index)
SELECT id, packing_list_entry_id, min_trip_duration, max_trip_duration, min_temperature, max_temperature, weather_condition, weather_min_probability, tag, NULL, NULL
FROM packing_list_conditions;

DROP TABLE packing_list_conditions;

ALTER TABLE packing_list_conditions_new RENAME TO packing_list_conditions;

PRAGMA foreign_keys = ON;
