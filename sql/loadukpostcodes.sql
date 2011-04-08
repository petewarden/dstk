-- See http://www.spatialdbadvisor.com/postgis_tips_tricks/118/loading-point-data-from-a-csv-file-in-postgis

CREATE TABLE uk_postcodes(
  postcode          char(7),
  latitude          float,
  longitude         float,
  country_code      char(3),
  nhs_region_code   char(3),
  nhs_code          char(3),
  county_code       char(2),
  district_code     char(2),
  ward_code         char(2)
);

COPY uk_postcodes ( postcode, latitude, longitude, country_code, nhs_region_code, nhs_code, county_code, district_code, ward_code )
  FROM '/home/ubuntu/sources/dstkdata/uk_postcodes.csv'
  WITH DELIMITER AS ',' CSV;
  
SELECT AddGeometryColumn('uk_postcodes', 'location', 4326, 'POINT', 2);

UPDATE uk_postcodes SET location = ST_SetSRID(ST_POINT(longitude,latitude),4326);

CREATE INDEX uk_postcodes_location ON uk_postcodes USING GIST ( location );

CREATE TABLE uk_ward_names(
  ward_code char(7),
  name      text,
  PRIMARY KEY(ward_code)
);

COPY uk_ward_names ( ward_code, name )
  FROM '/home/ubuntu/sources/dstkdata/uk_ward_names.csv'
  WITH DELIMITER AS ',' CSV;
