PRAGMA foreign_keys = OFF;

CREATE TABLE packing_list_conditions_old
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
        check ((min_trip_duration is not null
            and max_trip_duration is null
            and max_temperature is null
            and min_temperature is null
            and tag is null
            and weather_condition is null
            and weather_min_probability is null) or
               (max_trip_duration is not null
                   and min_trip_duration is null
                   and max_temperature is null
                   and min_temperature is null
                   and tag is null
                   and weather_condition is null
                   and weather_min_probability is null) or
               (min_temperature is not null
                   and min_trip_duration is null
                   and max_trip_duration is null
                   and max_temperature is null
                   and tag is null
                   and weather_condition is null
                   and weather_min_probability is null) or
               (max_temperature is not null
                   and min_trip_duration is null
                   and max_trip_duration is null
                   and min_temperature is null
                   and tag is null
                   and weather_condition is null
                   and weather_min_probability is null) or
               (tag is not null
                   and min_trip_duration is null
                   and max_trip_duration is null
                   and min_temperature is null
                   and max_temperature is null
                   and weather_condition is null
                   and weather_min_probability is null) or
               (weather_condition is not null
                   and weather_min_probability is not null
                   and min_trip_duration is null
                   and max_trip_duration is null
                   and min_temperature is null
                   and max_temperature is null
                   and tag is null))
);

INSERT INTO packing_list_conditions_old (id, packing_list_entry_id, min_trip_duration, max_trip_duration, min_temperature, max_temperature, weather_condition, weather_min_probability, tag)
SELECT id, packing_list_entry_id, min_trip_duration, max_trip_duration, min_temperature, max_temperature, weather_condition, weather_min_probability, tag
FROM packing_list_conditions
WHERE pollen_type IS NULL AND min_pollen_index IS NULL;

DROP TABLE packing_list_conditions;

ALTER TABLE packing_list_conditions_old RENAME TO packing_list_conditions;

DROP INDEX IF EXISTS pollen_daily_forecast_forecast_day_type_idx;
DROP TABLE pollen_daily_forecast;
DROP TABLE pollen_forecast;

ALTER TABLE locations DROP COLUMN pollen_information_last_updated;
ALTER TABLE accommodations DROP COLUMN pollen_information_last_updated;

PRAGMA foreign_keys = ON;
