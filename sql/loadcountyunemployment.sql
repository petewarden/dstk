
CREATE TABLE us_county_unemployment(
 state_code CHAR(2),
 county_code CHAR(3),
 year INTEGER,
 month INTEGER,
 value_type CHAR(2),
 value FLOAT,
 PRIMARY KEY(state_code, county_code, year, month, value_type)
);

-- If you hit duplicated primary key errors on this load, there's probably a few cities mistakenly
-- categorised as counties in the la.area file. You can fix this by adding the full codes of the
-- city versions to $blacklisted_blas in createblatofips.php and re-running the csv creation.
-- To detect duplicates, run this: 
-- sed 's/[0-9]\{1,\},\([0-9]\{1,\}\),.*/\1/' ../blsdata/blatofips.csv | sort | uniq -d

COPY us_county_unemployment ( state_code, county_code, year, month, value_type, value )
 FROM '/home/ubuntu/sources/blsdata/county_percentages.csv'
 WITH DELIMITER AS ',' CSV HEADER;
 
CREATE INDEX us_county_unemployment_state_county ON us_county_unemployment (state_code, county_code);
