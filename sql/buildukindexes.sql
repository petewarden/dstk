-- Builds indexes for the common queries on these tables

CREATE INDEX uk_osm_point_name_idx ON uk_osm_point ((lower(name)));
CREATE INDEX uk_osm_line_name_idx ON uk_osm_line ((lower(name)));

