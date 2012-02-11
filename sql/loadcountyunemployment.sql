-- See http://www.spatialdbadvisor.com/postgis_tips_tricks/118/loading point data from a csv file in postgis

CREATE TABLE us_county_unemployment(
 state_code CHAR(2),
 county_code CHAR(3),
 year INTEGER,
 month INTEGER,
 value_type CHAR(2),
 value FLOAT,
 PRIMARY KEY(state_code, county_code, year, month, value_type)
);

COPY us_county_unemployment ( state_code, county_code, year, month, value_type, value )
 FROM '/home/ubuntu/sources/blsdata/county_percentages.csv'
 WITH DELIMITER AS ',' CSV HEADER;
 
CREATE INDEX us_county_unemployment_state_county ON us_county_unemployment USING ( state_code, county_code );
