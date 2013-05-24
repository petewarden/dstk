CREATE TABLE ethnicity_of_surnames(
  name CHAR(32) PRIMARY KEY,
  rank INT,
  count INT,
  prop100k FLOAT,
  cum_prop100k FLOAT,
  pctwhite FLOAT,
  pctblack FLOAT,
  pctapi FLOAT,
  pctaian FLOAT,
  pct2prace FLOAT,
  pcthispanic FLOAT
);

COPY ethnicity_of_surnames(name, rank, count, prop100k, cum_prop100k, pctwhite, pctblack, pctapi, pctaian, pct2prace, pcthispanic)
  FROM '/home/ubuntu/sources/dstkdata/ethnicityofsurnames.csv'
  WITH DELIMITER AS ',' CSV HEADER;
  
CREATE TABLE first_names(
  name CHAR(16) PRIMARY KEY,
  count INT,
  male_percentage FLOAT,
  most_popular_year INT,
  earliest_common_year INT,
  latest_common_year INT
);

COPY first_names(name, count, male_percentage, most_popular_year, earliest_common_year, latest_common_year)
  FROM './babynames.csv'
  WITH DELIMITER AS ',' CSV HEADER;