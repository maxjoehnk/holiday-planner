ALTER TABLE routes DROP COLUMN scheduled_at;
ALTER TABLE routes DROP COLUMN day_order;
ALTER TABLE routes DROP COLUMN trip_day_id;

ALTER TABLE points_of_interest DROP COLUMN scheduled_at;
ALTER TABLE points_of_interest DROP COLUMN day_order;
ALTER TABLE points_of_interest DROP COLUMN trip_day_id;

drop table trip_day_locations;
drop table trip_days;
