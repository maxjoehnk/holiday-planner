-- ============================================================
-- Cross-device sync infrastructure — consolidated.
--
-- Creates the Postgres-side schema, RLS policies, helper functions,
-- triggers, storage bucket, and realtime publication entries that
-- back the offline-first sync layer.
--
-- Sharing is binary (you're either a trip's creator via `owner_id`
-- or a row in `trip_members`). Both confer identical read + write
-- access; only the owner attribution is kept for UI labelling. Any
-- member can invite or remove other members.
-- ============================================================

create extension if not exists "pgcrypto";

-- ============================================================
-- 1. Schema: tables, indexes, constraints.
-- ============================================================

-- ---- profiles -----------------------------------------------------
create table public.profiles
(
    id           uuid primary key references auth.users (id) on delete cascade,
    email        text        not null,
    display_name text,
    updated_at   timestamptz not null default now()
);

-- ---- trips --------------------------------------------------------
-- Header images live in the `attachments` Storage bucket rather than
-- inline as bytea (which would inflate every trip pull by megabytes).
-- header_image_path follows the same `trips/<trip_id>/...` convention
-- as regular attachments, header_image_sha256 lets clients skip
-- re-downloading bytes they already have, and header_image_uploaded_at
-- is the local push state — non-null on the row that pushed it, copied
-- from the wire on apply so other clients don't redundantly re-upload.
create table public.trips
(
    id                         uuid primary key,
    owner_id                   uuid        not null references auth.users (id) on delete cascade,
    name                       text        not null,
    start_date                 timestamptz not null,
    end_date                   timestamptz not null,
    header_image_path          text,
    header_image_sha256        text,
    header_image_uploaded_at   timestamptz,
    updated_at                 timestamptz not null default now(),
    deleted_at                 timestamptz,
    last_modified_by           uuid
);
create index trips_owner_idx      on public.trips (owner_id);
create index trips_updated_at_idx on public.trips (updated_at);

-- ---- trip_members + trip_invites ---------------------------------
create table public.trip_members
(
    trip_id    uuid        not null references public.trips (id) on delete cascade,
    user_id    uuid        not null references auth.users (id) on delete cascade,
    added_at   timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz,
    primary key (trip_id, user_id)
);
create index trip_members_updated_at_idx on public.trip_members (updated_at);
create index trip_members_user_idx       on public.trip_members (user_id);

create table public.trip_invites
(
    id         uuid primary key     default gen_random_uuid(),
    trip_id    uuid        not null references public.trips (id) on delete cascade,
    email      text        not null,
    invited_by uuid        not null references auth.users (id),
    created_at timestamptz not null default now()
);
create unique index trip_invites_unique_pending
    on public.trip_invites (trip_id, lower(email));

-- ---- trip-scoped sub-tables --------------------------------------
create table public.accommodations
(
    id                    uuid primary key,
    trip_id               uuid        not null references public.trips (id) on delete cascade,
    name                  text        not null,
    check_in              timestamptz,
    check_out             timestamptz,
    address               text,
    coordinates_latitude  double precision,
    coordinates_longitude double precision,
    updated_at            timestamptz not null default now(),
    deleted_at            timestamptz,
    last_modified_by      uuid
);
create index accommodations_trip_idx       on public.accommodations (trip_id);
create index accommodations_updated_at_idx on public.accommodations (updated_at);

create table public.attachments
(
    id               uuid primary key,
    trip_id          uuid        not null references public.trips (id) on delete cascade,
    name             text        not null,
    file_name        text        not null,
    content_type     text        not null,
    storage_path     text,
    sha256           text,
    uploaded_at      timestamptz,
    updated_at       timestamptz not null default now(),
    deleted_at       timestamptz,
    last_modified_by uuid
);
create index attachments_trip_idx       on public.attachments (trip_id);
create index attachments_updated_at_idx on public.attachments (updated_at);

create table public.locations
(
    id                               uuid primary key,
    trip_id                          uuid             not null references public.trips (id) on delete cascade,
    coordinates_latitude             double precision not null,
    coordinates_longitude            double precision not null,
    city                             text             not null,
    country                          text             not null,
    is_coastal                       boolean          not null default false,
    tidal_information_last_updated   timestamptz,
    weather_information_last_updated timestamptz,
    updated_at                       timestamptz      not null default now(),
    deleted_at                       timestamptz,
    last_modified_by                 uuid
);
create index locations_trip_idx       on public.locations (trip_id);
create index locations_updated_at_idx on public.locations (updated_at);

create table public.car_rentals
(
    id               uuid primary key,
    trip_id          uuid        not null references public.trips (id) on delete cascade,
    provider         text        not null,
    pick_up_date     timestamptz not null,
    pick_up_location text        not null,
    return_date      timestamptz not null,
    return_location  text,
    booking_number   text,
    updated_at       timestamptz not null default now(),
    deleted_at       timestamptz,
    last_modified_by uuid
);
create index car_rentals_trip_idx       on public.car_rentals (trip_id);
create index car_rentals_updated_at_idx on public.car_rentals (updated_at);

create table public.reservations
(
    id               uuid primary key,
    trip_id          uuid        not null references public.trips (id) on delete cascade,
    title            text        not null,
    address          text,
    start_date       timestamptz not null,
    end_date         timestamptz,
    link             text,
    booking_number   text,
    category         text        not null default 'restaurant'
        check (category in ('restaurant', 'activity')),
    updated_at       timestamptz not null default now(),
    deleted_at       timestamptz,
    last_modified_by uuid
);
create index reservations_trip_idx       on public.reservations (trip_id);
create index reservations_updated_at_idx on public.reservations (updated_at);

create table public.points_of_interest
(
    id                    uuid primary key,
    trip_id               uuid        not null references public.trips (id) on delete cascade,
    name                  text        not null,
    address               text        not null,
    website               text,
    opening_hours         text,
    price                 text,
    phone_number          text,
    note                  text,
    coordinates_latitude  double precision,
    coordinates_longitude double precision,
    -- Day-planner assignment. trip_day_id references public.trip_days
    -- via the FK below — the table is declared further down so the
    -- FK is added in a deferred ALTER (after both tables exist).
    trip_day_id           uuid,
    day_order             integer,
    scheduled_at          timestamptz,
    updated_at            timestamptz not null default now(),
    deleted_at            timestamptz,
    last_modified_by      uuid
);
create index points_of_interest_trip_idx       on public.points_of_interest (trip_id);
create index points_of_interest_updated_at_idx on public.points_of_interest (updated_at);
create index points_of_interest_trip_day_idx   on public.points_of_interest (trip_day_id);

create table public.trains
(
    id                           uuid primary key,
    trip_id                      uuid        not null references public.trips (id) on delete cascade,
    train_number                 text,
    departure_station_name       text        not null,
    departure_station_city       text,
    departure_station_country    text,
    departure_scheduled_platform text        not null,
    arrival_station_name         text        not null,
    arrival_station_city         text,
    arrival_station_country      text,
    arrival_scheduled_platform   text        not null,
    scheduled_departure_time     timestamptz not null,
    scheduled_arrival_time       timestamptz not null,
    updated_at                   timestamptz not null default now(),
    deleted_at                   timestamptz,
    last_modified_by             uuid
);
create index trains_trip_idx       on public.trains (trip_id);
create index trains_updated_at_idx on public.trains (updated_at);

-- Tags are a shared global library — anyone can append a new one, no
-- one can rename or delete (append-only). The id is deterministic from
-- a v5 UUID of the lowercased name, so a client that types "Beach"
-- locally ends up with the same uuid as everyone else who used the
-- name. Personal attribution lives in `user_tags` (below), not on the
-- tag row itself, so each user can claim a tag independently even when
-- a different user inserted it first.
create table public.tags
(
    id           uuid primary key,
    name         text        not null,
    updated_at   timestamptz not null default now()
);
create unique index tags_name_unique_lower on public.tags (lower(name));
create index tags_updated_at_idx           on public.tags (updated_at);

-- user_tags: per-user attribution. One row per (user, tag) pair tells
-- the sync layer "this user has this tag in their personal library".
-- Created when a user creates or assigns a tag. Sync brings these to
-- every device the user signs in on, which is what makes a brand-new
-- device see tags the user typed elsewhere even if the global row was
-- first created by someone else.
create table public.user_tags
(
    user_id    uuid        not null references auth.users (id) on delete cascade,
    tag_id     uuid        not null references public.tags  (id) on delete cascade,
    added_at   timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    -- Soft-delete carries the "I no longer want this tag in my
    -- library" intent across devices. The row stays so future
    -- realtime / pull traffic can settle on its `deleted_at` via LWW.
    deleted_at timestamptz,
    primary key (user_id, tag_id)
);
create index user_tags_user_idx       on public.user_tags (user_id);
create index user_tags_tag_idx        on public.user_tags (tag_id);
create index user_tags_updated_at_idx on public.user_tags (updated_at);

-- ---- Join tables --------------------------------------------------
create table public.accommodation_attachments
(
    accommodation_id uuid        not null references public.accommodations (id) on delete cascade,
    attachment_id    uuid        not null references public.attachments (id) on delete cascade,
    updated_at       timestamptz not null default now(),
    deleted_at       timestamptz,
    primary key (accommodation_id, attachment_id)
);
create index accommodation_attachments_updated_at_idx on public.accommodation_attachments (updated_at);

create table public.location_attachments
(
    location_id   uuid        not null references public.locations (id) on delete cascade,
    attachment_id uuid        not null references public.attachments (id) on delete cascade,
    updated_at    timestamptz not null default now(),
    deleted_at    timestamptz,
    primary key (location_id, attachment_id)
);
create index location_attachments_updated_at_idx on public.location_attachments (updated_at);

create table public.trip_tags
(
    trip_id    uuid        not null references public.trips (id) on delete cascade,
    tag_id     uuid        not null references public.tags (id)  on delete cascade,
    updated_at timestamptz not null default now(),
    deleted_at timestamptz,
    primary key (trip_id, tag_id)
);
create index trip_tags_updated_at_idx on public.trip_tags (updated_at);

-- ---- trip_days (per-day planner) ---------------------------------
-- Each trip_day represents one calendar day inside a trip's range, plus
-- optional title. routes / points_of_interest can attach to a day via
-- their `trip_day_id` column (no FK from server side; the client
-- resolves day membership from the synced trip_days rows).
create table public.trip_days
(
    id               uuid primary key,
    trip_id          uuid        not null references public.trips (id) on delete cascade,
    date             date        not null,
    title            text,
    updated_at       timestamptz not null default now(),
    deleted_at       timestamptz,
    last_modified_by uuid
);
create unique index trip_days_trip_date_unique
    on public.trip_days (trip_id, date)
    where deleted_at is null;
create index trip_days_trip_idx       on public.trip_days (trip_id);
create index trip_days_updated_at_idx on public.trip_days (updated_at);

-- ---- trip_day_locations -----------------------------------------
-- Composite-PK join table assigning a Location to a TripDay, with an
-- `is_primary` flag and `display_order` so the planner UI can render
-- the locations in the right order. Soft-delete only — the deleted_at
-- column carries unassignments across devices.
create table public.trip_day_locations
(
    trip_day_id   uuid        not null references public.trip_days (id) on delete cascade,
    location_id   uuid        not null references public.locations  (id) on delete cascade,
    is_primary    boolean     not null default false,
    display_order integer     not null default 0,
    updated_at    timestamptz not null default now(),
    deleted_at    timestamptz,
    primary key (trip_day_id, location_id)
);
create index trip_day_locations_loc_idx        on public.trip_day_locations (location_id);
create index trip_day_locations_updated_at_idx on public.trip_day_locations (updated_at);

-- ---- routes (Komoot tours) ---------------------------------------
-- Komoot route imports per trip; can be assigned to a planner day via
-- `trip_day_id`. Provider + provider_route_id is unique per trip so
-- the same tour isn't imported twice into the same trip.
create table public.routes
(
    id                    uuid primary key,
    trip_id               uuid        not null references public.trips (id) on delete cascade,
    provider              text        not null,
    provider_route_id     text        not null,
    name                  text        not null,
    sport                 text,
    distance_meters       double precision not null,
    duration_seconds      bigint      not null,
    elevation_up_meters   double precision,
    elevation_down_meters double precision,
    start_latitude        double precision not null,
    start_longitude       double precision not null,
    polyline              text        not null,
    note                  text,
    external_url          text        not null,
    trip_day_id           uuid        references public.trip_days (id) on delete set null,
    day_order             integer,
    scheduled_at          timestamptz,
    updated_at            timestamptz not null default now(),
    deleted_at            timestamptz,
    last_modified_by      uuid
);
create unique index routes_trip_provider_route_unique
    on public.routes (trip_id, provider, provider_route_id)
    where deleted_at is null;
create index routes_trip_idx       on public.routes (trip_id);
create index routes_updated_at_idx on public.routes (updated_at);

-- FK from points_of_interest.trip_day_id → trip_days(id). The
-- column was declared above when trip_days didn't exist yet; we
-- add the constraint now that both tables are in place.
alter table public.points_of_interest
    add constraint points_of_interest_trip_day_id_fkey
    foreign key (trip_day_id) references public.trip_days (id)
    on delete set null;

-- ---- Append-only activity log ------------------------------------
create table public.trip_activity
(
    id            uuid primary key      default gen_random_uuid(),
    trip_id       uuid        not null references public.trips (id) on delete cascade,
    entity_type   text        not null,
    entity_id     uuid        not null,
    entity_label  text,
    action        text        not null check (action in ('insert', 'update', 'delete')),
    actor_user_id uuid        references auth.users (id) on delete set null,
    occurred_at   timestamptz not null default now()
);
create index trip_activity_trip_idx on public.trip_activity (trip_id, occurred_at desc);

-- ============================================================
-- 2. SECURITY DEFINER membership helpers.
--
-- Single-arg signatures using `auth.uid()` internally — callers
-- can't spoof another user's identity. The helpers bypass RLS
-- on their inner reads so the parent policies don't recurse.
-- ============================================================

create or replace function public.user_owns_trip(p_trip_id uuid)
returns boolean
language sql
security definer set search_path = public
stable
as $$
    select exists (
        select 1 from public.trips
         where id = p_trip_id
           and owner_id = auth.uid()
    );
$$;

create or replace function public.user_is_trip_member(p_trip_id uuid)
returns boolean
language sql
security definer set search_path = public
stable
as $$
    select exists (
        select 1 from public.trip_members
         where trip_id = p_trip_id
           and user_id = auth.uid()
           and deleted_at is null
    );
$$;

create or replace function public.user_can_access_trip(p_trip_id uuid)
returns boolean
language sql
security definer set search_path = public
stable
as $$
    select public.user_owns_trip(p_trip_id)
        or public.user_is_trip_member(p_trip_id);
$$;

revoke execute on function public.user_owns_trip(uuid)       from public, anon;
revoke execute on function public.user_is_trip_member(uuid)  from public, anon;
revoke execute on function public.user_can_access_trip(uuid) from public, anon;
grant  execute on function public.user_owns_trip(uuid)       to authenticated;
grant  execute on function public.user_is_trip_member(uuid)  to authenticated;
grant  execute on function public.user_can_access_trip(uuid) to authenticated;

-- ============================================================
-- 3. RLS policies.
--
-- `auth.uid()` calls in policy bodies are wrapped in
-- `(select auth.uid())` so the planner hoists them out of the
-- per-row evaluation.
-- ============================================================

alter table public.profiles enable row level security;
-- A user can see their own profile, plus the profile of anyone they
-- share a trip with (member-of-the-same-trip OR owner-of-a-trip-I'm-in).
-- The earlier "any signed-in user can read every profile" policy
-- leaked emails and display names across unrelated accounts.
create policy "profiles_read_shared_trip" on public.profiles
    for select
    using (
        id = (select auth.uid())
        or exists (
            select 1 from public.trip_members tm
             where tm.user_id = profiles.id
               and tm.deleted_at is null
               and public.user_can_access_trip(tm.trip_id)
        )
        or exists (
            select 1 from public.trips t
             where t.owner_id = profiles.id
               and t.deleted_at is null
               and public.user_can_access_trip(t.id)
        )
    );
create policy "profiles_update_self" on public.profiles
    for update
    using (id = (select auth.uid()))
    with check (id = (select auth.uid()));

-- Column-level grants so a PATCH /profiles?id=eq.<me> can only touch
-- display_name and updated_at. Without this, the RLS WITH CHECK above
-- only verifies the row identity — a caller could PATCH `email`
-- alongside `display_name` and spoof another user's email in the
-- member list. The id column is intentionally not granted: changing
-- it would re-key the row, and SECURITY DEFINER triggers
-- (handle_new_user) own row creation.
revoke update on public.profiles from anon, authenticated;
grant  update (display_name, updated_at) on public.profiles to authenticated;

alter table public.trips enable row level security;
create policy "trips_member_or_owner_all" on public.trips
    for all
    using (
        owner_id = (select auth.uid())
        or public.user_is_trip_member(id)
    )
    with check (
        owner_id = (select auth.uid())
        or public.user_is_trip_member(id)
    );

-- Sub-tables — same policy shape, gated on user_can_access_trip.
do $$
declare
    t text;
begin
    foreach t in array array[
        'accommodations',
        'attachments',
        'locations',
        'car_rentals',
        'reservations',
        'points_of_interest',
        'trains'
    ]
    loop
        execute format('alter table public.%I enable row level security', t);
        execute format($f$
            create policy "%s_via_trip" on public.%I
                for all
                using (public.user_can_access_trip(%I.trip_id))
                with check (public.user_can_access_trip(%I.trip_id))
        $f$, t, t, t, t);
    end loop;
end $$;

-- Join tables
alter table public.accommodation_attachments enable row level security;
create policy "accommodation_attachments_via_accommodation" on public.accommodation_attachments
    for all
    using (
        public.user_can_access_trip(
            (select trip_id from public.accommodations where id = accommodation_attachments.accommodation_id)
        )
    )
    with check (
        public.user_can_access_trip(
            (select trip_id from public.accommodations where id = accommodation_attachments.accommodation_id)
        )
    );

alter table public.location_attachments enable row level security;
create policy "location_attachments_via_location" on public.location_attachments
    for all
    using (
        public.user_can_access_trip(
            (select trip_id from public.locations where id = location_attachments.location_id)
        )
    )
    with check (
        public.user_can_access_trip(
            (select trip_id from public.locations where id = location_attachments.location_id)
        )
    );

alter table public.trip_tags enable row level security;
create policy "trip_tags_via_trip" on public.trip_tags
    for all
    using (public.user_can_access_trip(trip_tags.trip_id))
    with check (public.user_can_access_trip(trip_tags.trip_id));

alter table public.trip_days enable row level security;
create policy "trip_days_via_trip" on public.trip_days
    for all
    using (public.user_can_access_trip(trip_days.trip_id))
    with check (public.user_can_access_trip(trip_days.trip_id));

alter table public.routes enable row level security;
create policy "routes_via_trip" on public.routes
    for all
    using (public.user_can_access_trip(routes.trip_id))
    with check (public.user_can_access_trip(routes.trip_id));

-- trip_day_locations doesn't carry trip_id directly; gate on its day's
-- trip via a join through public.trip_days.
alter table public.trip_day_locations enable row level security;
create policy "trip_day_locations_via_day" on public.trip_day_locations
    for all
    using (
        exists (
            select 1 from public.trip_days td
             where td.id = trip_day_locations.trip_day_id
               and public.user_can_access_trip(td.trip_id)
        )
    )
    with check (
        exists (
            select 1 from public.trip_days td
             where td.id = trip_day_locations.trip_day_id
               and public.user_can_access_trip(td.trip_id)
        )
    );

-- Tags are a global, append-only library. Reads are gated to tags the
-- caller has in their personal library (user_tags) plus tags linked
-- via trip_tags to a trip they can access — so the global library is
-- not enumerable. INSERT is open to any authenticated user; per-user
-- attribution is recorded by a separate user_tags row, which prevents
-- this row from being the access lever (the user_tags policy is what
-- gates personal-library writes). UPDATE / DELETE are intentionally
-- absent — RLS denies by default, so nobody can rename or drop a tag.
alter table public.tags enable row level security;
create policy "tags_read_visible" on public.tags
    for select
    using (
        exists (
            select 1 from public.user_tags ut
             where ut.tag_id = tags.id
               and ut.user_id = (select auth.uid())
               and ut.deleted_at is null
        )
        or exists (
            select 1 from public.trip_tags tt
             where tt.tag_id = tags.id
               and tt.deleted_at is null
               and public.user_can_access_trip(tt.trip_id)
        )
    );
create policy "tags_insert_authenticated" on public.tags
    for insert
    with check ((select auth.uid()) is not null);

-- user_tags: each user reads, inserts, and updates only their own
-- rows. UPDATE is what lets a user soft-delete (= remove from their
-- library); we don't allow row deletion since the deleted_at flag is
-- the carrier of "removed" across devices via LWW.
alter table public.user_tags enable row level security;
create policy "user_tags_self_read" on public.user_tags
    for select
    using (user_id = (select auth.uid()));
create policy "user_tags_self_insert" on public.user_tags
    for insert
    with check (user_id = (select auth.uid()));
create policy "user_tags_self_update" on public.user_tags
    for update
    using (user_id = (select auth.uid()))
    with check (user_id = (select auth.uid()));

-- Membership tables — any member of the trip can manage.
alter table public.trip_members enable row level security;
create policy "trip_members_member_writes" on public.trip_members
    for all
    using (public.user_can_access_trip(trip_id))
    with check (public.user_can_access_trip(trip_id));

alter table public.trip_invites enable row level security;
create policy "trip_invites_member_all" on public.trip_invites
    for all
    using (public.user_can_access_trip(trip_id))
    with check (public.user_can_access_trip(trip_id));

-- Append-only activity log — readable via membership; writes are
-- triggers-only.
alter table public.trip_activity enable row level security;
create policy "trip_activity_via_trip" on public.trip_activity
    for select
    to authenticated
    using (public.user_can_access_trip(trip_id));

-- ============================================================
-- 4. Triggers.
-- ============================================================

-- claim_pending_invites_for: convert every pending trip_invite for the
-- given (user_id, email) into a trip_members row, then drop the invite.
-- Used by both the new-signup trigger and the per-sign-in trigger so an
-- account that was invited *before* it existed still gets the trip on
-- the next login.
create or replace function public.claim_pending_invites_for(
    p_user_id uuid,
    p_email   text
)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
    insert into public.trip_members (trip_id, user_id)
    select i.trip_id, p_user_id
      from public.trip_invites i
     where lower(i.email) = lower(p_email)
    on conflict (trip_id, user_id) do nothing;

    delete from public.trip_invites
     where lower(email) = lower(p_email);
end;
$$;

revoke execute on function public.claim_pending_invites_for(uuid, text)
    from public, anon, authenticated;

-- handle_new_user: populate profile + claim pending invites on signup.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
    insert into public.profiles (id, email, display_name)
    values (
        new.id,
        new.email,
        coalesce(new.raw_user_meta_data->>'display_name', new.email)
    )
    on conflict (id) do update set
        email = excluded.email;

    perform public.claim_pending_invites_for(new.id, new.email);

    return new;
end;
$$;

revoke execute on function public.handle_new_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute procedure public.handle_new_user();

-- claim_pending_invites_on_signin: existing users who were invited
-- before they signed in to this device pick the invite up on their
-- next sign-in. Without this trigger, invite_to_trip would have to
-- look up auth.users to handle existing users — and that lookup is an
-- account-existence oracle (the caller learns whether the email has
-- an account from the return shape).
create or replace function public.claim_pending_invites_on_signin()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
    perform public.claim_pending_invites_for(new.id, new.email);
    return new;
end;
$$;

revoke execute on function public.claim_pending_invites_on_signin()
    from public, anon, authenticated;

drop trigger if exists on_auth_user_sign_in on auth.users;
create trigger on_auth_user_sign_in
    after update of last_sign_in_at on auth.users
    for each row
    when (old.last_sign_in_at is distinct from new.last_sign_in_at)
    execute procedure public.claim_pending_invites_on_signin();

-- log_trip_activity: append a row to trip_activity for every change.
create or replace function public.log_trip_activity()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
    v_new       jsonb := case when tg_op <> 'DELETE' then to_jsonb(new) else null end;
    v_old       jsonb := case when tg_op <> 'INSERT' then to_jsonb(old) else null end;
    v_row       jsonb := coalesce(v_new, v_old);
    v_trip_id   uuid;
    v_entity_id uuid := (v_row->>'id')::uuid;
    v_label     text;
    v_action    text;
    v_actor     uuid;
begin
    v_trip_id := case tg_table_name
        when 'trips' then v_entity_id
        else (v_row->>'trip_id')::uuid
    end;

    v_label := case tg_table_name
        when 'trips'              then v_row->>'name'
        when 'accommodations'     then v_row->>'name'
        when 'locations'          then v_row->>'city'
        when 'reservations'       then v_row->>'title'
        when 'car_rentals'        then v_row->>'provider'
        when 'points_of_interest' then v_row->>'name'
        when 'trains'             then
            (v_row->>'departure_station_name') || ' → ' || (v_row->>'arrival_station_name')
        else null
    end;

    if tg_op = 'INSERT' then
        v_action := 'insert';
    elsif tg_op = 'DELETE' then
        v_action := 'delete';
    elsif (v_old->>'deleted_at') is null and (v_new->>'deleted_at') is not null then
        v_action := 'delete';
    else
        v_action := 'update';
    end if;

    v_actor := coalesce(
        (v_row->>'last_modified_by')::uuid,
        auth.uid()
    );

    -- Skip logging if the parent trip is already gone. Happens during
    -- owner hard-delete: the AFTER DELETE trigger fires after the trip
    -- row (and cascaded children) are removed, so the FK on
    -- trip_activity.trip_id would reject the insert. No useful log
    -- entry to make at that point anyway — the whole trip is going.
    if not exists (select 1 from public.trips where id = v_trip_id) then
        return null;
    end if;

    insert into public.trip_activity
        (trip_id, entity_type, entity_id, entity_label, action, actor_user_id)
    values
        (v_trip_id, tg_table_name::text, v_entity_id, v_label, v_action, v_actor);

    return null;
end;
$$;

revoke execute on function public.log_trip_activity() from public, anon, authenticated;

do $$
declare
    t text;
begin
    foreach t in array array[
        'trips',
        'accommodations',
        'locations',
        'reservations',
        'car_rentals',
        'points_of_interest',
        'trains'
    ]
    loop
        execute format(
            'create trigger log_activity_%s
                after insert or update or delete on public.%I
                for each row execute function public.log_trip_activity()',
            t, t
        );
    end loop;
end $$;

-- scrub_obsolete_header_image: when a trip's header_image_path
-- changes (the client mints a new key per byte change so other
-- devices pick up the change via a path diff), delete the old
-- storage.objects row. Supabase's storage backend picks up the
-- deletion and removes the underlying file from the bucket. Doing
-- this server-side instead of client-side means a client crash
-- between minting the new path and firing the scrub doesn't orphan
-- the old object — and it works regardless of which member did the
-- edit.
create or replace function public.scrub_obsolete_header_image()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
    if (old.header_image_path is distinct from new.header_image_path)
       and old.header_image_path is not null
    then
        delete from storage.objects
         where bucket_id = 'attachments'
           and name = old.header_image_path;
    end if;
    return new;
end;
$$;

revoke execute on function public.scrub_obsolete_header_image() from public, anon, authenticated;

create trigger trips_scrub_obsolete_header
    before update on public.trips
    for each row execute procedure public.scrub_obsolete_header_image();

-- ============================================================
-- 5. invite_to_trip RPC.
-- ============================================================

-- Always inserts the invite, regardless of whether the email already
-- corresponds to a registered user. The on_auth_user_sign_in trigger
-- claims the invite the next time that user signs in (and
-- handle_new_user covers the brand-new-signup case). This avoids the
-- caller being able to differentiate "user exists" from "user doesn't
-- exist" via the return value — the previous version's auth.users
-- lookup was an account-existence oracle for any trip member.
create or replace function public.invite_to_trip(
    p_trip_id uuid,
    p_email   text
)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
    v_caller uuid := auth.uid();
begin
    if v_caller is null then
        raise exception 'Not signed in';
    end if;

    if not public.user_can_access_trip(p_trip_id) then
        raise exception 'You don''t have access to this trip';
    end if;

    insert into public.trip_invites (trip_id, email, invited_by)
    values (p_trip_id, lower(p_email), v_caller)
    on conflict (trip_id, lower(email)) do nothing;
end;
$$;

revoke execute on function public.invite_to_trip(uuid, text) from public, anon;
grant  execute on function public.invite_to_trip(uuid, text) to authenticated;

-- ---- delete_my_account RPC ---------------------------------------
-- Wipes the caller's server-side data and tears down their auth row.
-- Everything else falls out via cascade FKs:
--   * trips (owner_id → auth.users CASCADE)
--   * trip_members (user_id → auth.users CASCADE)
--   * profiles (id → auth.users CASCADE)
--   * trip_invites we received cascade via trip deletion.
-- The one FK without a cascade is trip_invites.invited_by, so we clear
-- those explicitly before nuking the auth row.

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
begin
    if v_user_id is null then
        raise exception 'Not signed in';
    end if;

    -- Wipe every Storage blob the caller uploaded. There's no FK between
    -- public.attachments and storage.objects, so the cascade about to
    -- fire on auth.users wouldn't touch the actual files — they'd live
    -- on as orphans. Supabase stamps `owner` on every object with the
    -- uploader's uuid, which covers files the caller put into trips they
    -- own AND files they uploaded as a member of someone else's trip.
    -- SECURITY DEFINER lets us bypass storage RLS.
    delete from storage.objects
     where bucket_id = 'attachments'
       and owner = v_user_id;

    delete from public.trip_invites where invited_by = v_user_id;
    delete from auth.users           where id = v_user_id;
end;
$$;

revoke execute on function public.delete_my_account() from public, anon;
grant  execute on function public.delete_my_account() to authenticated;

-- ============================================================
-- 6. Storage bucket + policy.
-- ============================================================

insert into storage.buckets (id, name, public)
values ('attachments', 'attachments', false)
on conflict (id) do nothing;

drop policy if exists "attachments_via_trip" on storage.objects;
create policy "attachments_via_trip" on storage.objects
    for all
    to authenticated
    using (
        bucket_id = 'attachments'
        and name ~ '^trips/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/'
        and public.user_can_access_trip(
            (split_part(name, '/', 2))::uuid
        )
    )
    with check (
        bucket_id = 'attachments'
        and name ~ '^trips/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/'
        and public.user_can_access_trip(
            (split_part(name, '/', 2))::uuid
        )
    );

-- ============================================================
-- 7. Realtime publication.
-- ============================================================

do $$
declare
    t text;
begin
    foreach t in array array[
        'trips',
        'accommodations',
        'attachments',
        'locations',
        'car_rentals',
        'reservations',
        'points_of_interest',
        'trains',
        'tags',
        'user_tags',
        'accommodation_attachments',
        'location_attachments',
        'trip_tags',
        'trip_days',
        'trip_day_locations',
        'routes',
        'trip_members',
        -- `trip_invites` is intentionally NOT published. Clients
        -- never sync it (handle_new_user / claim_pending_invites_on_signin
        -- consume invites server-side), and broadcasting it leaks
        -- invitee email addresses over the realtime channel to every
        -- trip member's websocket.
        'profiles',
        'trip_activity'
    ]
    loop
        begin
            execute format('alter publication supabase_realtime add table public.%I', t);
        exception when duplicate_object then null;
        end;
        -- Realtime needs the full old row on UPDATE/DELETE for clients to
        -- learn which row to apply. Default identity ships only the PK
        -- old-value, and DELETE arrives with an empty `old` payload, so
        -- clients can't reconcile the deletion locally.
        execute format('alter table public.%I replica identity full', t);
    end loop;
end $$;

-- Belt-and-braces: in case an earlier migration run added
-- `trip_invites` to the publication, drop it now. The current loop
-- above no longer includes it.
do $$
begin
    alter publication supabase_realtime drop table public.trip_invites;
exception when undefined_object then null;
end $$;

-- ============================================================
-- 8. Lock the `anon` role out of the schema.
--
-- The app only talks to PostgREST as `authenticated`; anon never
-- needs to read or call anything in `public`. Default privileges
-- get adjusted so future tables stay locked.
-- ============================================================

do $$
declare
    t record;
begin
    for t in
        select schemaname, tablename
          from pg_tables
         where schemaname = 'public'
    loop
        execute format(
            'revoke all on table %I.%I from anon',
            t.schemaname, t.tablename
        );
    end loop;
end $$;

do $$
declare
    s record;
begin
    for s in
        select schemaname, sequencename
          from pg_sequences
         where schemaname = 'public'
    loop
        execute format(
            'revoke all on sequence %I.%I from anon',
            s.schemaname, s.sequencename
        );
    end loop;
end $$;

alter default privileges in schema public revoke all on tables    from anon;
alter default privileges in schema public revoke all on sequences from anon;
alter default privileges in schema public revoke all on functions from anon;

-- trip_activity is read-only for clients; writes happen only via
-- triggers.
revoke all    on public.trip_activity from anon, authenticated;
grant  select on public.trip_activity to   authenticated;
