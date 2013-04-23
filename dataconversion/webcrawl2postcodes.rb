#!/usr/bin/env ruby

require 'rubygems'

require 'json'

$stdin.each_line do |line|

  url, json_string = line.split("\t", 2)

  if !url or !json_string then next end

  json_string.gsub!("\t", ' ')

  begin
    data = JSON.parse(json_string)
  rescue JSON::ParserError => e
    $stderr.puts "JSON Parse Error on '#{line}'"
    next
  end

  if !data['location'] or
    !data['location']['postalCode'] or
    !data['location']['cc'] or
    !data['location']['lat'] or
    !data['location']['lng']
    # Missing essential data, skip
    next
  end

  location = data['location']
  lat = location['lat']
  lon = location['lng']
  country_code = location['cc']
  postal_code = location['postalCode']

  place_name = location['city'] || ''
  admin_name1 = location['state'] || ''

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
