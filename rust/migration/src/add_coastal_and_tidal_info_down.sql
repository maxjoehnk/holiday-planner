drop table tidal_information;

ALTER TABLE locations DROP COLUMN is_coastal;
ALTER TABLE locations DROP COLUMN tidal_information_last_updated;
