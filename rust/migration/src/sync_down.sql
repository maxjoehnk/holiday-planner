DROP INDEX IF EXISTS idx_user_tags_tag_id;
DROP INDEX IF EXISTS idx_user_tags_user_id;
DROP TABLE IF EXISTS user_tags;

DROP INDEX IF EXISTS trip_activity_trip_idx;
DROP TABLE IF EXISTS trip_activity;

DROP INDEX IF EXISTS idx_trip_members_user_id;
DROP TABLE IF EXISTS trip_members;

DROP TABLE IF EXISTS profiles;

DROP TABLE IF EXISTS sync_cursors;

DROP INDEX IF EXISTS idx_pending_mutations_entity;
DROP INDEX IF EXISTS idx_pending_mutations_created_at;
DROP TABLE IF EXISTS pending_mutations;

ALTER TABLE trip_day_locations DROP COLUMN deleted_at;
ALTER TABLE trip_day_locations DROP COLUMN updated_at;

ALTER TABLE routes DROP COLUMN last_modified_by;
ALTER TABLE routes DROP COLUMN deleted_at;
ALTER TABLE routes DROP COLUMN updated_at;

ALTER TABLE trip_days DROP COLUMN last_modified_by;
ALTER TABLE trip_days DROP COLUMN deleted_at;
ALTER TABLE trip_days DROP COLUMN updated_at;

ALTER TABLE trip_tags DROP COLUMN deleted_at;
ALTER TABLE trip_tags DROP COLUMN updated_at;

ALTER TABLE location_attachments DROP COLUMN deleted_at;
ALTER TABLE location_attachments DROP COLUMN updated_at;

ALTER TABLE accommodation_attachments DROP COLUMN deleted_at;
ALTER TABLE accommodation_attachments DROP COLUMN updated_at;

ALTER TABLE tags DROP COLUMN updated_at;

ALTER TABLE trains DROP COLUMN last_modified_by;
ALTER TABLE trains DROP COLUMN deleted_at;
ALTER TABLE trains DROP COLUMN updated_at;

ALTER TABLE points_of_interest DROP COLUMN last_modified_by;
ALTER TABLE points_of_interest DROP COLUMN deleted_at;
ALTER TABLE points_of_interest DROP COLUMN updated_at;

ALTER TABLE reservations DROP COLUMN last_modified_by;
ALTER TABLE reservations DROP COLUMN deleted_at;
ALTER TABLE reservations DROP COLUMN updated_at;

ALTER TABLE car_rentals DROP COLUMN last_modified_by;
ALTER TABLE car_rentals DROP COLUMN deleted_at;
ALTER TABLE car_rentals DROP COLUMN updated_at;

ALTER TABLE locations DROP COLUMN last_modified_by;
ALTER TABLE locations DROP COLUMN deleted_at;
ALTER TABLE locations DROP COLUMN updated_at;

ALTER TABLE attachments DROP COLUMN uploaded_at;
ALTER TABLE attachments DROP COLUMN sha256;
ALTER TABLE attachments DROP COLUMN storage_path;
ALTER TABLE attachments DROP COLUMN last_modified_by;
ALTER TABLE attachments DROP COLUMN deleted_at;
ALTER TABLE attachments DROP COLUMN updated_at;

ALTER TABLE accommodations DROP COLUMN last_modified_by;
ALTER TABLE accommodations DROP COLUMN deleted_at;
ALTER TABLE accommodations DROP COLUMN updated_at;

ALTER TABLE trips DROP COLUMN header_image_uploaded_at;
ALTER TABLE trips DROP COLUMN header_image_sha256;
ALTER TABLE trips DROP COLUMN header_image_path;
ALTER TABLE trips DROP COLUMN detached_at;
ALTER TABLE trips DROP COLUMN owner_id;
ALTER TABLE trips DROP COLUMN last_modified_by;
ALTER TABLE trips DROP COLUMN deleted_at;
ALTER TABLE trips DROP COLUMN updated_at;
