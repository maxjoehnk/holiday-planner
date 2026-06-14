create table routes
(
    id blob not null constraint routes_pk primary key,
    trip_id blob not null constraint routes_trip_id_fk references trips on delete cascade,
    provider text not null,
    provider_route_id text not null,
    name text not null,
    sport text,
    distance_meters real not null,
    duration_seconds integer not null,
    elevation_up_meters real,
    elevation_down_meters real,
    start_latitude real not null,
    start_longitude real not null,
    polyline text not null,
    note text,
    external_url text not null
);

create unique index routes_trip_provider_route_idx
    on routes (trip_id, provider, provider_route_id);
