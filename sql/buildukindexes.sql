-- Builds indexes for the common queries on these tables

CREATE INDEX ON uk_osm_point ((lower(name)));
CREATE INDEX ON uk_osm_line ((lower(name)));

