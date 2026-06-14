-- ============================================================
-- Cross-device sync schema — consolidated.
--
-- Adds sync metadata columns to existing trip-scoped tables,
-- creates the outbox + cursor tables, the membership + activity
-- tables, and supporting indexes.
--
-- Date / timestamp columns are declared TEXT (not INTEGER) because
-- SeaORM with sqlx-sqlite encodes `chrono::DateTime<Utc>` as RFC3339
-- strings; matching the declared type to the stored format avoids
-- the integer-vs-text ambiguity that earlier incremental migrations
-- accidentally introduced.
-- ============================================================

-- ------------------------------------------------------------
-- Sync metadata columns on every synced parent + child table.
-- ------------------------------------------------------------

ALTER TABLE trips ADD COLUMN updated_at       TEXT NOT NULL DEFAULT '1970-01-01T00:00:00Z';
ALTER TABLE trips ADD COLUMN deleted_at       TEXT;
ALTER TABLE trips ADD COLUMN last_modified_by TEXT;
ALTER TABLE trips ADD COLUMN owner_id         TEXT;
-- Set when the server-side trip has been deleted out from under us
-- (e.g. the owner hard-deleted and our membership cascaded away). The
-- local snapshot stays available as a read-only copy until the user
-- re-claims it for their own account.
ALTER TABLE trips ADD COLUMN detached_at      TEXT;
-- Header image is stored in the `attachments` Storage bucket; the
-- bytes still live in the `header_image` blob column locally, but
-- pushes / pulls only carry the path + hash + upload timestamp.
ALTER TABLE trips ADD COLUMN header_image_path        TEXT;
ALTER TABLE trips ADD COLUMN header_image_sha256      TEXT;
ALTER TABLE trips ADD COLUMN header_image_uploaded_at TEXT;

ALTER TABLE accommodations ADD COLUMN updated_at       TEXT NOT NULL DEFAULT '1970-01-01T00:00:00Z';
ALTER TABLE accommodations ADD COLUMN deleted_at       TEXT;
ALTER TABLE accommodations ADD COLUMN last_modified_by TEXT;

ALTER TABLE attachments ADD COLUMN updated_at       TEXT NOT NULL DEFAULT '1970-01-01T00:00:00Z';
ALTER TABLE attachments ADD COLUMN deleted_at       TEXT;
ALTER TABLE attachments ADD COLUMN last_modified_by TEXT;
ALTER TABLE attachments ADD COLUMN storage_path     TEXT;
ALTER TABLE attachments ADD COLUMN sha256           TEXT;
ALTER TABLE attachments ADD COLUMN uploaded_at      TEXT;

ALTER TABLE locations ADD COLUMN updated_at       TEXT NOT NULL DEFAULT '1970-01-01T00:00:00Z';
ALTER TABLE locations ADD COLUMN deleted_at       TEXT;
ALTER TABLE locations ADD COLUMN last_modified_by TEXT;

ALTER TABLE car_rentals ADD COLUMN updated_at       TEXT NOT NULL DEFAULT '1970-01-01T00:00:00Z';
ALTER TABLE car_rentals ADD COLUMN deleted_at       TEXT;
ALTER TABLE car_rentals ADD COLUMN last_modified_by TEXT;

ALTER TABLE reservations ADD COLUMN updated_at       TEXT NOT NULL DEFAULT '1970-01-01T00:00:00Z';
ALTER TABLE reservations ADD COLUMN deleted_at       TEXT;
ALTER TABLE reservations ADD COLUMN last_modified_by TEXT;

ALTER TABLE points_of_interest ADD COLUMN updated_at       TEXT NOT NULL DEFAULT '1970-01-01T00:00:00Z';
ALTER TABLE points_of_interest ADD COLUMN deleted_at       TEXT;
ALTER TABLE points_of_interest ADD COLUMN last_modified_by TEXT;

ALTER TABLE trains ADD COLUMN updated_at       TEXT NOT NULL DEFAULT '1970-01-01T00:00:00Z';
ALTER TABLE trains ADD COLUMN deleted_at       TEXT;
ALTER TABLE trains ADD COLUMN last_modified_by TEXT;

ALTER TABLE tags ADD COLUMN updated_at TEXT NOT NULL DEFAULT '1970-01-01T00:00:00Z';

ALTER TABLE accommodation_attachments ADD COLUMN updated_at TEXT NOT NULL DEFAULT '1970-01-01T00:00:00Z';
ALTER TABLE accommodation_attachments ADD COLUMN deleted_at TEXT;

ALTER TABLE location_attachments ADD COLUMN updated_at TEXT NOT NULL DEFAULT '1970-01-01T00:00:00Z';
ALTER TABLE location_attachments ADD COLUMN deleted_at TEXT;

ALTER TABLE trip_tags ADD COLUMN updated_at TEXT NOT NULL DEFAULT '1970-01-01T00:00:00Z';
ALTER TABLE trip_tags ADD COLUMN deleted_at TEXT;

-- ------------------------------------------------------------
-- Outbox for the push worker. One row per pending mutation.
-- ------------------------------------------------------------
CREATE TABLE pending_mutations
(
    id          BLOB    NOT NULL CONSTRAINT pending_mutations_pk PRIMARY KEY,
    entity_type TEXT    NOT NULL,
    entity_id   BLOB    NOT NULL,
    operation   TEXT    NOT NULL CHECK (operation IN ('insert', 'update', 'delete')),
    payload     TEXT    NOT NULL,
    created_at  TEXT    NOT NULL,
    attempts    INTEGER NOT NULL DEFAULT 0,
    last_error  TEXT
);
CREATE INDEX idx_pending_mutations_created_at ON pending_mutations (created_at);
CREATE INDEX idx_pending_mutations_entity     ON pending_mutations (entity_type, entity_id);

-- ------------------------------------------------------------
-- Pull cursors keyed by table name.
-- ------------------------------------------------------------
CREATE TABLE sync_cursors
(
    entity_type    TEXT    NOT NULL CONSTRAINT sync_cursors_pk PRIMARY KEY,
    last_pulled_at INTEGER NOT NULL DEFAULT 0
);

-- ------------------------------------------------------------
-- Profiles: cached display info for every user we share a trip with.
-- ------------------------------------------------------------
CREATE TABLE profiles
(
    id           BLOB NOT NULL CONSTRAINT profiles_pk PRIMARY KEY,
    email        TEXT NOT NULL,
    display_name TEXT,
    updated_at   TEXT NOT NULL DEFAULT '1970-01-01T00:00:00Z',
    deleted_at   TEXT
);

-- ------------------------------------------------------------
-- Trip membership graph (no role distinction).
-- ------------------------------------------------------------
CREATE TABLE trip_members
(
    trip_id    BLOB NOT NULL
        CONSTRAINT trip_members_trip_id_fk
            REFERENCES trips
            ON DELETE CASCADE,
    user_id    BLOB NOT NULL,
    added_at   TEXT NOT NULL DEFAULT '1970-01-01T00:00:00Z',
    updated_at TEXT NOT NULL DEFAULT '1970-01-01T00:00:00Z',
    deleted_at TEXT,
    CONSTRAINT trip_members_pk PRIMARY KEY (trip_id, user_id)
);
CREATE INDEX idx_trip_members_user_id ON trip_members (user_id);

-- ------------------------------------------------------------
-- Append-only activity log; server-populated, client read-only.
-- ------------------------------------------------------------
CREATE TABLE trip_activity
(
    id            BLOB NOT NULL CONSTRAINT trip_activity_pk PRIMARY KEY,
    trip_id       BLOB NOT NULL
        CONSTRAINT trip_activity_trip_id_fk
            REFERENCES trips
            ON DELETE CASCADE,
    entity_type   TEXT NOT NULL,
    entity_id     BLOB NOT NULL,
    entity_label  TEXT,
    action        TEXT NOT NULL CHECK (action IN ('insert', 'update', 'delete')),
    actor_user_id BLOB,
    occurred_at   TEXT NOT NULL
);
CREATE INDEX trip_activity_trip_idx ON trip_activity (trip_id, occurred_at DESC);

-- ------------------------------------------------------------
-- Per-user tag library. One row per (user, tag) tells sync "this
-- tag is in this user's library". Lets a tag get to all of the
-- user's devices even when the global tag row was first created
-- by someone else. Append-only.
-- ------------------------------------------------------------
CREATE TABLE user_tags
(
    user_id    BLOB NOT NULL,
    tag_id     BLOB NOT NULL,
    added_at   TEXT NOT NULL DEFAULT '1970-01-01T00:00:00Z',
    updated_at TEXT NOT NULL DEFAULT '1970-01-01T00:00:00Z',
    deleted_at TEXT,
    CONSTRAINT user_tags_pk PRIMARY KEY (user_id, tag_id)
);
CREATE INDEX idx_user_tags_user_id ON user_tags (user_id);
CREATE INDEX idx_user_tags_tag_id  ON user_tags (tag_id);
