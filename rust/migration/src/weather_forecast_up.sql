create table weather_forecast
(
    id          blob not null
        constraint weather_forecast_pk
            primary key,
    location_id blob not null
        constraint weather_forecast_location_id_fk
            references locations
            on delete cascade
);

create table weather_daily_forecast
(
    id                        blob    not null
        constraint weather_daily_forecast_pk
            primary key,
    forecast_id               blob    not null
        constraint weather_daily_forecast_weather_forecast_id_fk
            references weather_forecast
            on delete cascade,
    day                       integer not null,
    min_temperature           real    not null,
    max_temperature           real    not null,
    morning_temperature       real    not null,
    day_temperature           real    not null,
    evening_temperature       real    not null,
    night_temperature         real    not null,
    precipitation_amount      real    not null,
    precipitation_probability real    not null,
    wind_speed                real    not null,
    condition                 integer not null
);

create table weather_hourly_forecast
(
    id                        blob    not null
        constraint weather_hourly_forecast_pk
            primary key,
    forecast_id               real    not null
        constraint weather_hourly_forecast_weather_forecast_id_fk
            references weather_forecast
            on delete cascade,
    time                      integer not null,
    temperature               real    not null,
    wind_speed                real    not null,
    precipitation_amount      real    not null,
    precipitation_probability real    not null,
    condition                 integer not null
);

