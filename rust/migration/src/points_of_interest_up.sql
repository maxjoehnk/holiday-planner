create table points_of_interest
(
    id blob not null constraint points_of_interest_pk primary key,
    trip_id blob not null constraint points_of_interest_trip_id_fk references trips on delete cascade,
    name text not null,
    address text not null,
    website text,
    opening_hours text,
    price text
);
