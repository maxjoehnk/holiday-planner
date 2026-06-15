PRAGMA foreign_keys = OFF;

ALTER TABLE accommodations ADD COLUMN weather_information_last_updated DATETIME;

CREATE TABLE weather_forecast_new
(
    id               blob not null
        constraint weather_forecast_pk
            primary key,
    location_id      blob
        constraint weather_forecast_location_id_fk
            references locations
            on delete cascade,
    accommodation_id blob
        constraint weather_forecast_accommodation_id_fk
            references accommodations
            on delete cascade,
    constraint weather_forecast_owner_xor
        check ((location_id is not null and accommodation_id is null)
            or (location_id is null and accommodation_id is not null))
);

INSERT INTO weather_forecast_new (id, location_id, accommodation_id)
SELECT id, location_id, NULL FROM weather_forecast;

DROP TABLE weather_forecast;

ALTER TABLE weather_forecast_new RENAME TO weather_forecast;

PRAGMA foreign_keys = ON;
