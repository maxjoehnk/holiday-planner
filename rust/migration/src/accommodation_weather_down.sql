PRAGMA foreign_keys = OFF;

CREATE TABLE weather_forecast_old
(
    id          blob not null
        constraint weather_forecast_pk
            primary key,
    location_id blob not null
        constraint weather_forecast_location_id_fk
            references locations
            on delete cascade
);

INSERT INTO weather_forecast_old (id, location_id)
SELECT id, location_id FROM weather_forecast WHERE location_id IS NOT NULL;

DROP TABLE weather_forecast;

ALTER TABLE weather_forecast_old RENAME TO weather_forecast;

ALTER TABLE accommodations DROP COLUMN weather_information_last_updated;

PRAGMA foreign_keys = ON;
