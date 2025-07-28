ALTER TABLE locations ADD COLUMN is_coastal BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE locations ADD COLUMN tidal_information_last_updated DATETIME;

CREATE TABLE tidal_information (
                                   id TEXT PRIMARY KEY,
                                   location_id TEXT NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
                                   date DATETIME NOT NULL,
                                   height REAL NOT NULL,
                                   tide TEXT NOT NULL CHECK (tide IN ('high', 'low'))
);

CREATE INDEX idx_tidal_information_location_id ON tidal_information(location_id);
CREATE INDEX idx_tidal_information_date ON tidal_information(date);
CREATE INDEX idx_tidal_information_location_date ON tidal_information(location_id, date);
