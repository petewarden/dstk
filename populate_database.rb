#!/usr/bin/env ruby

require 'rubygems'

require 'geodict_lib'
require 'postgres'
require 'csv'

def load_cities(conn)

  begin
    conn.exec('DROP TABLE cities')
  rescue RuntimeError
    # ignore errors here
  end

  conn.exec('CREATE TABLE cities (
        city VARCHAR(80),
        country CHAR(2),
        region_code CHAR(2),
        population INT,
        lat FLOAT,
        lon FLOAT,
        last_word VARCHAR(32),
        PRIMARY KEY (city, country));')
  conn.exec('CREATE INDEX city_last_word_index ON cities(last_word)')
  
  file_name = GeodictConfig::SOURCE_FOLDER+'worldcitiespop.csv'
  File.foreach(file_name) do |line|    
    begin
      row = CSV.parse_line(line)
      country = row[0]
      city = row[1]
      region_code = row[3]
      population = row[4]
      lat = row[5]
      lon = row[6]
    rescue
      printf(STDERR, 'Problem with '+line)
      next
    end

    if !population or population == ''
      population = 0
    end

    begin

      city.strip!

      last_word, index, skipped = pull_word_from_end(city, city.length-1, false)

      conn.exec("INSERT INTO cities (city, country, region_code, population, lat, lon, last_word)
        values ("+
        "'"+PGconn.escape(city)+"'"+
        ", '"+PGconn.escape(country)+"'"+
        ", '"+PGconn.escape(region_code)+"'"+
        ", '"+PGconn.escape(population.to_s)+"'"+
        ", '"+PGconn.escape(lat.to_s)+"'"+
        ", '"+PGconn.escape(lon.to_s)+"'"+
        ", '"+PGconn.escape(last_word)+"')"
      );
    rescue
      # do nothing
    end
  end
  
end

def load_countries(conn)
  begin
    conn.exec('DROP TABLE countries')
  rescue RuntimeError
    # ignore errors here
  end

  conn.exec('CREATE TABLE countries (
    country VARCHAR(64),
    PRIMARY KEY(country),
    country_code CHAR(2),
    lat FLOAT,
    lon FLOAT,
    last_word VARCHAR(32))')
  conn.exec('CREATE INDEX country_last_word_index ON countries(last_word)')
  
  country_positions = {}
  
  file_name = GeodictConfig::SOURCE_FOLDER+'countrypositions.csv'
  File.foreach(file_name) do |line|    
    begin
      row = CSV.parse_line(line)
      country_code = row[0]
      lat = row[1]
      lon = row[2]
    rescue
      printf(STDERR, 'Problem with '+line)
      next
    end
    
    country_positions[country_code] = { :lat => lat, :lon => lon }
  end
  
  file_name = GeodictConfig::SOURCE_FOLDER+'countrynames.csv'
  File.foreach(file_name) do |line|    
    begin
      row = CSV.parse_line(line)
      country_code = row[0]
      country_names = row[1]
    rescue
      printf(STDERR, 'Problem with '+line)
      next
    end
    
    country_names_list = country_names.split(' | ')
        
    lat = country_positions[country_code][:lat]
    lon = country_positions[country_code][:lon]
        
    country_names_list.each do |country_name|
        
      begin

        country_name.strip!
            
        last_word, index, skipped = pull_word_from_end(country_name, country_name.length-1, false)

        conn.exec("INSERT INTO countries (country, country_code, lat, lon, last_word)
          values ("+
          "'"+PGconn.escape(country_name)+"'"+
          ", '"+PGconn.escape(country_code)+"'"+
          ", '"+PGconn.escape(lat.to_s)+"'"+
          ", '"+PGconn.escape(lon.to_s)+"'"+
          ", '"+PGconn.escape(last_word)+"')"
        );
      
      rescue
        printf(STDERR, 'Problem with country '+country_name)
      end

    end

  end

end

def load_regions(conn)
  begin
    conn.exec('DROP TABLE regions')
  rescue RuntimeError
    # ignore errors here
  end
  
  conn.exec('CREATE TABLE regions (
    region VARCHAR(64),
    PRIMARY KEY(region),
    region_code CHAR(4),
    country_code CHAR(2),
    lat FLOAT,
    lon FLOAT,
    last_word VARCHAR(32))')
  conn.exec('CREATE INDEX region_last_word_index ON regions(last_word)')

  us_state_positions = {}

  file_name = GeodictConfig::SOURCE_FOLDER+'us_statepositions.csv'
  File.foreach(file_name) do |line|    
    begin
      row = CSV.parse_line(line)
      region_code = row[0]
      lat = row[1]
      lon = row[2]
    rescue
      printf(STDERR, 'Problem with '+line)
      next
    end
    
    us_state_positions[region_code] = { :lat => lat, :lon => lon }
  
  end

  country_code = 'US'

  file_name = GeodictConfig::SOURCE_FOLDER+'us_statenames.csv'
  File.foreach(file_name) do |line|    
    begin
      row = CSV.parse_line(line)
      region_code = row[0]
      state_names = row[2]
    rescue
      printf(STDERR, 'Problem with '+line)
      next
    end
    
    state_names_list = state_names.split('|')
        
    lat = us_state_positions[region_code][:lat]
    lon = us_state_positions[region_code][:lon]
        
    state_names_list.each do |state_name|
    
      begin
        state_name.strip!
            
        last_word, index, skipped = pull_word_from_end(state_name, state_name.length-1, false)
        
        conn.exec("INSERT INTO regions (region, region_code, country_code, lat, lon, last_word)
          values ("+
          "'"+PGconn.escape(state_name)+"'"+
          ", '"+PGconn.escape(region_code)+"'"+
          ", '"+PGconn.escape(country_code)+"'"+
          ", '"+PGconn.escape(lat.to_s)+"'"+
          ", '"+PGconn.escape(lon.to_s)+"'"+
          ", '"+PGconn.escape(last_word)+"')"
        );
      rescue
        printf(STDERR, 'Problem with region '+state_name+"\n")
        # do nothing
      end

    end

  end

end
    

conn = get_database_connection()

load_cities(conn)
load_countries(conn)
load_regions(conn)

