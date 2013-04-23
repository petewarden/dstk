#!/usr/bin/env ruby

require 'rubygems'

require 'json'

$stdin.each_line do |line|

  line.gsub!("\t", ' ')

  begin
    data = JSON.parse(line)
  rescue JSON::ParserError => e
    $stderr.puts "JSON Parse Error on '#{line}'"
    next
  end

  if !data['geometry'] or
    !data['geometry']['coordinates'] or
    !data['properties'] or
    !data['properties']['country'] or
    !data['properties']['postcode']
    # Missing essential data, skip
    next
  end

  geometry = data['geometry']
  properties = data['properties']

  coordinates = geometry['coordinates']
  lon = coordinates[0].to_s
  lat = coordinates[1].to_s

  country_code = properties['country']
  postal_code = properties['postcode']

  place_name = properties['city'] || ''
  admin_name1 = properties['province'] || ''

  admin_code1 = ''
  admin_name2 = ''
  admin_code2 = ''
  admin_name3 = ''
  admin_code3 = ''
  accuracy = '1'

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
