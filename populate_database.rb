#!/usr/bin/env ruby

require 'rubygems'

require 'postgres'
require 'csv'

# Some hackiness to include the library script, even if invoked from another directory
require File.join(File.expand_path(File.dirname(__FILE__)), 'geodict_lib')

def load_cities(conn)

  begin
    conn.exec('DROP TABLE cities')
  rescue
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
        PRIMARY KEY (city, country, region_code));')
  conn.exec('CREATE INDEX city_last_word_index ON cities(last_word)')
  
  file_name = DSTKConfig::SOURCE_FOLDER+'worldcitiespop.csv'
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
  rescue
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
  
  file_name = DSTKConfig::SOURCE_FOLDER+'countrypositions.csv'
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
  
  file_name = DSTKConfig::SOURCE_FOLDER+'countrynames.csv'
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
  rescue
    # ignore errors here
  end
  
  conn.exec('CREATE TABLE regions (
    region VARCHAR(64),
    region_code CHAR(4),
    country_code CHAR(2),
    lat FLOAT,
    lon FLOAT,
    last_word VARCHAR(32))')

  load_us_regions(conn)

  load_non_us_regions(conn)
  
end

def load_us_regions(conn)

  us_state_positions = {}

  file_name = DSTKConfig::SOURCE_FOLDER+'us_statepositions.csv'
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

  file_name = DSTKConfig::SOURCE_FOLDER+'us_statenames.csv'
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

def load_non_us_regions(conn)

  have_loaded_region = {}

  file_name = DSTKConfig::SOURCE_FOLDER+'geonames_postalcodes.tsv'
  File.foreach(file_name) do |line|    
    row = line.split("\t")
    country_code = row[0]
    postal_code = row[1]
    place_name = row[2]
    admin_name1 = row[3]
    admin_code1 = row[4]
    admin_name2 = row[5]
    admin_code2 = row[6]
    admin_name3 = row[7]
    admin_code3 = row[8]
    lat = row[9]
    lon = row[10]
    accuracy = row[11]

    if country_code == 'US' then next end
    if !admin_name1 or admin_name1 == '' then next end
    if !admin_code1 or admin_code1 == '' then next end
    if !lat or lat == '' then next end
    if !lon or lon == '' then next end
    
    key = admin_name1 + '_' + country_code
    if have_loaded_region[key]
      next
    end
    have_loaded_region[key] = true
    
    state_names_list = [admin_name1, admin_code1]
        
    state_names_list.each do |state_name|
    
      state_name.strip!
          
      last_word, index, skipped = pull_word_from_end(state_name, state_name.length-1, false)
      
      sql = "INSERT INTO regions (region, region_code, country_code, lat, lon, last_word)
        values ("+
        "'"+PGconn.escape(state_name)+"'"+
        ", '"+PGconn.escape(admin_code1)+"'"+
        ", '"+PGconn.escape(country_code)+"'"+
        ", '"+PGconn.escape(lat.to_s)+"'"+
        ", '"+PGconn.escape(lon.to_s)+"'"+
        ", '"+PGconn.escape(last_word)+"')"
      conn.exec(sql)

    end

  end

end

def load_postal_codes(conn)
  begin
    conn.exec('DROP TABLE postal_codes')
  rescue
    # ignore errors here
  end

  conn.exec('CREATE TABLE postal_codes (
    postal_code VARCHAR(64),
    region_code CHAR(4),
    country_code CHAR(2),
    lat FLOAT,
    lon FLOAT,
    last_word VARCHAR(32))')
  
  postal_codes = {}

  file_name = DSTKConfig::SOURCE_FOLDER+'geonames_postalcodes.tsv'
  File.foreach(file_name) do |line|    
    row = line.split("\t")
    country_code = row[0]
    postal_code = row[1]
    place_name = row[2]
    admin_name1 = row[3]
    admin_code1 = row[4]
    admin_name2 = row[5]
    admin_code2 = row[6]
    admin_name3 = row[7]
    admin_code3 = row[8]
    lat_string = row[9]
    lon_string = row[10]
    accuracy = row[11]

    if !postal_code or postal_code == '' then next end
    if !admin_code1 or admin_code1 == '' then next end
    if !lat_string or lat_string == '' then next end
    if !lon_string or lon_string == '' then next end
    
    key = country_code + '*' + postal_code
    if !postal_codes[key]
      postal_codes[key] = {
        'postal_code' => postal_code,
        'region_code' => admin_code1,
        'country_code' => country_code,
        'coordinates' => []
      }
    end
    postal_codes[key]['coordinates'] << {'lat' => lat_string.to_f, 'lon' => lon_string.to_f}
  end

  postal_codes.each do |key, info|

    postal_code = info['postal_code']
    region_code = info['region_code']
    country_code = info['country_code']
    coordinates = info['coordinates']
    last_word, index, skipped = pull_word_from_end(postal_code, postal_code.length-1, false)

    lat = 0.0
    lon = 0.0
    coordinates.each do |position|
      lat += position['lat']
      lon += position['lon']
    end
    lat = (lat / coordinates.length)
    lon = (lon / coordinates.length)
    
    sql = "INSERT INTO postal_codes (postal_code, region_code, country_code, lat, lon, last_word)
      values ("+
      "'"+PGconn.escape(postal_code)+"'"+
      ", '"+PGconn.escape(region_code)+"'"+
      ", '"+PGconn.escape(country_code)+"'"+
      ", '"+PGconn.escape(lat.to_s)+"'"+
      ", '"+PGconn.escape(lon.to_s)+"'"+
      ", '"+PGconn.escape(last_word)+"')"
    conn.exec(sql)

  end

  conn.exec('CREATE INDEX postal_codes_last_word_index ON postal_codes(last_word)')

end

conn = get_database_connection()

load_cities(conn)
load_countries(conn)
load_regions(conn)
load_postal_codes(conn)
