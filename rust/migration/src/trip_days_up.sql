create table trip_days
(
    id blob not null constraint trip_days_pk primary key,
    trip_id blob not null constraint trip_days_trip_id_fk references trips on delete cascade,
    date text not null,
    title text
);

create unique index trip_days_trip_date_idx on trip_days (trip_id, date);
create index trip_days_trip_id_idx on trip_days (trip_id);

create table trip_day_locations
(
    trip_day_id blob not null constraint trip_day_locations_trip_day_id_fk references trip_days on delete cascade,
    location_id blob not null constraint trip_day_locations_location_id_fk references locations on delete cascade,
    is_primary integer not null default 0,
    display_order integer not null default 0,
    constraint trip_day_locations_pk primary key (trip_day_id, location_id)
);

create index trip_day_locations_location_id_idx on trip_day_locations (location_id);

ALTER TABLE points_of_interest ADD COLUMN trip_day_id blob references trip_days on delete set null;
ALTER TABLE points_of_interest ADD COLUMN day_order integer;
ALTER TABLE points_of_interest ADD COLUMN scheduled_at text;

ALTER TABLE routes ADD COLUMN trip_day_id blob references trip_days on delete set null;
ALTER TABLE routes ADD COLUMN day_order integer;
ALTER TABLE routes ADD COLUMN scheduled_at text;
