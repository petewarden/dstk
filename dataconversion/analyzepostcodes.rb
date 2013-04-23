#!/usr/bin/env ruby

require 'rubygems'

require 'json'

def output_row(country_code, postal_code, place_name, admin_name1, points)

  lat_array = points.map do | point| point['lat'] end
  lon_array = points.map do | point| point['lon'] end

  lat = (lat_array.max + lat_array.min) / 2.0
  # This won't work for dateline spanning postal codes, but those should be rare?
  lon = (lon_array.max + lon_array.min) / 2.0

  admin_code1 = admin_name1
  admin_name2 = ''
  admin_code2 = ''
  admin_name3 = ''
  admin_code3 = ''

  if points.length < 3
    accuracy = '1'
  else
    accuracy = '2'
  end

  puts [
    country_code,
    postal_code,
    place_name,
    admin_name1,
    admin_code1,
    admin_name2,
    admin_code2,
    admin_name3,
    admin_code3,
    lat,
    lon,
    accuracy,
  ].join("\t")
  
end

previous_country_code = nil
previous_postal_code = nil
previous_place_name = nil
previous_admin_name1 = nil
points = []

$stdin.each_line do |line|
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
  if !admin_name1 or admin_name1 == '' then next end
  if !lat_string or lat_string == '' then next end
  if !lon_string or lon_string == '' then next end

  lat = lat_string.to_f
  lon = lon_string.to_f

  if !lat or !lon then next end

  if postal_code != previous_postal_code or country_code != previous_country_code
    if previous_postal_code
      output_row(previous_country_code, previous_postal_code, previous_place_name, previous_admin_name1, points)
    end
    previous_country_code = country_code
    previous_postal_code = postal_code
    previous_place_name = place_name
    previous_admin_name1 = admin_name1
    points = []
  end

  points << {'lat' => lat, 'lon' => lon}

end

output_row(previous_country_code, previous_postal_code, previous_place_name, previous_admin_name1, points)
