# Street2Coordinates
#
# This module takes a series of postal addresses and tries to resolve them into
# latitude/longitude coordinates. 
#
# Copyright (C) 2010 Pete Warden <pete@petewarden.com>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'rubygems'

# A horrible hack to work around my problems getting the Geocoder to install as a gem
$LOAD_PATH.unshift '../geocoder/lib'
require 'geocoder/us/database'

# Some hackiness to include the library script, even if invoked from another directory
cwd = File.expand_path(File.dirname(__FILE__))
require File.join(cwd, 'dstk_config')
require File.join(cwd, 'geodict_lib')


# Keep a singleton accessor for the geocoder object, so we don't leak resources
# Fix for https://github.com/petewarden/dstk/issues/4
$geocoder_db = nil

S2C_WHITESPACE = '(([ \t.,;]+)|^|$)'

def s2c_debug_log(message)
  printf(STDERR, "%s\n" % message)
end

# Takes an array of postal addresses as input, and looks up their locations using
# data from the US census
def street2coordinates(addresses)

  if !$geocoder_db
    db_file = nil
    DSTKConfig::GEOCODER_DB_FILES.each do |file|
      if File.exists(file)
        db_file = file
        break
      end
    end
    if !db_file
      raise "street2coordinates(): Couldn't find any geocoder database files"
    end
    $geocoder_db = Geocoder::US::Database.new(db_file, {:debug => false})
  end

  conn = get_reverse_geo_db_connection

  default_country = guess_top_country_for_list(addresses)

  output = {}
  addresses.each do |address|
    begin
      country = guess_country_for_address(address) or default_country
      if country == 'us'
        info = geocode_us_address(address)
      elsif country == 'uk'
        info = geocode_uk_address(address, conn)
      else
        info = nil
      end
    rescue
      printf(STDERR, $!.inspect + $@.inspect + "\n")
      info = nil
    end
    output[address] = info
  end
    
  return output

end

# Looks through the list of addresses, tries to guess which country each one belongs to
# by looking for evidence like explicit country names, distinctive postal codes or 
# known region or city names, and returns the most frequent for use as a default. 
def guess_top_country_for_list(addresses)

  country_votes = {}
  addresses.each do |address|
  
    country = guess_country_for_address(address)

    if country
      if !country_votes.has_key?(country)
        country_votes[country] = 0
      end
      country_votes[country] += 1
    end
  
  end
  
  if country_votes.length == 0
    return nil
  end
  
  top_countries = country_votes.sort do |a,b| b[1]<=>a[1] end
  top_country = top_countries[0][0]

  top_country
  
end

# Looks for clues in the address that indicate which country it's in
def guess_country_for_address(address)

  if looks_like_us_address(address)
    return 'us'
  end

  if looks_like_uk_address(address)
    return 'uk'
  end

  return nil
end

# Searches for either explicit country name, or a known state followed by a zip code
def looks_like_us_address(address)

  country_names = '(U\.?S\.?A?\.?|United States|America)'
  country_names_suffix_re = Regexp.new(S2C_WHITESPACE+country_names+S2C_WHITESPACE+'?$', Regexp::IGNORECASE)

  if country_names_suffix_re.match(address)
    return true
  end

  state_names_list = [
    'AK',
    'Alaska',
    'AL',
    'Alabama',
    'AR',
    'Arkansas',
    'AZ',
    'Arizona',
    'CA',
    'California',
    'CO',
    'Colorado',
    'CT',
    'Connecticut',
    'DE',
    'Delaware',
    'DC',
    'District of Columbia',
    'FL',
    'Florida',
    'GA',
    'Georgia',
    'HI',
    'Hawaii',
    'ID',
    'Idaho',
    'IL',
    'Illinois',
    'IN',
    'Indiana',
    'IA',
    'Iowa',
    'KS',
    'Kansas',
    'KY',
    'Kentucky',
    'LA',
    'Louisiana',
    'ME',
    'Maine',
    'MD',
    'Maryland',
    'MA',
    'Massachusetts',
    'MI',
    'Michigan',
    'MN',
    'Minnesota',
    'MS',
    'Mississippi',
    'MO',
    'Missouri',
    'MT',
    'Montana',
    'NE',
    'Nebraska',
    'NV',
    'Nevada',
    'NH',
    'New Hamp(shire)?',
    'NJ',
    'New Jersey',
    'NM',
    'New Mexico',
    'NY',
    'New York',
    'NC',
    'North Carolina',
    'ND',
    'North Dakota',
    'OH',
    'Ohio',
    'OK',
    'Oklahoma',
    'OR',
    'Oregon',
    'PA',
    'Pennsylvania',
    'RI',
    'Rhode Island',
    'SC',
    'South Carolina',
    'SD',
    'South Dakota',
    'TN',
    'Tennessee',
    'TX',
    'Texas',
    'UT',
    'Utah',
    'VT',
    'Vermont',
    'VA',
    'Virginia',
    'WA',
    'Washington',
    'WV',
    'West Virginia',
    'WI',
    'Wisconsin',
    'WY',
    'Wyoming',
  ]
  
  state_names = '('+state_names_list.join('|')+')'
  
  zip_code = '\d\d\d\d\d(-\d\d\d\d)?'
  
  state_zip_suffix_re = Regexp.new(S2C_WHITESPACE+state_names+'('+S2C_WHITESPACE+zip_code+')?'+S2C_WHITESPACE+'?$', Regexp::IGNORECASE)
  
  if state_zip_suffix_re.match(address)
    return true
  end

  return false
end

# Looks for a country name, county name, or something that looks like a post code
def looks_like_uk_address(address)

  country_names = '(U\.?K\.?|United Kingdom|Great Britain|England|Scotland|Wales)'
  country_names_suffix_re = Regexp.new(S2C_WHITESPACE+country_names+S2C_WHITESPACE+'?$', Regexp::IGNORECASE)

  if country_names_suffix_re.match(address)
    return true
  end

  county_names_list = [
    'aberdeen(shire)?',
    'abertawe',
    'angus',
    'argyll and bute',
    'ayr(shire)?',
    'barnsley',
    'bedford',
    'bedford(shire)?',
    'berk(shire)?',
    'birmingham',
    'blackpool',
    'blaenau gwent',
    'bolton',
    'bournemouth',
    'bracknell forest',
    'bradford',
    'bridgend',
    'brighton and hove',
    'bristol',
    'bro morgannwg',
    'buckingham(shire)?',
    'bury',
    'caerdydd',
    'caerffili',
    'caerphilly',
    'calderdale',
    'cambridge(shire)?',
    'cardiff',
    'carmarthen(shire)?',
    'casnewydd',
    'castell-nedd port talbot',
    'central bedford(shire)?',
    'ceredigion',
    'che(shire)?',
    'clackmannan(shire)?',
    'conwy',
    'cornwall',
    'county durham',
    'coventry',
    'cumbria',
    'darlington',
    'denbigh(shire)?',
    'derby',
    'derby(shire)?',
    'devon',
    'doncaster',
    'dorset',
    'dudley',
    'dumfries and galloway',
    'dunbarton(shire)?',
    'dundee city',
    'durham',
    'edinburgh',
    'eilean siar',
    'essex',
    'falkirk',
    'fife',
    'flint(shire)?',
    'gateshead',
    'glasgow',
    'gloucester(shire)?',
    'greater manchester',
    'gwynedd',
    'halton',
    'hamp(shire)?',
    'hartlepool',
    'hereford(shire)?',
    'hertford(shire)?',
    'highland',
    'inverclyde',
    'isle of anglesey',
    'isle of wight',
    'isles of scilly',
    'kent',
    'kingston upon hull',
    'kirklees',
    'knowsley',
    'lanark(shire)?',
    'lanca(shire)?',
    'leeds',
    'leicester',
    'leicester(shire)?',
    'lincoln(shire)?',
    'liverpool',
    'london',
    'lothian',
    'luton',
    'manchester',
    'medway',
    'merseyside',
    'merthyr tudful',
    'merthyr tydfil',
    'middlesbrough',
    'midlands',
    'midlothian',
    'milton keynes',
    'monmouth(shire)?',
    'moray',
    'na h-eileanan an iar',
    'neath port talbot',
    'newcastle upon tyne',
    'newport',
    'norfolk',
    'northampton(shire)?',
    'northumberland',
    'nottingham',
    'nottingham(shire)?',
    'oldham',
    'orkney islands',
    'oxford(shire)?',
    'pembroke(shire)?',
    'pen-y-bont ar ogwr',
    'perth and kinross',
    'peterborough',
    'plymouth',
    'poole',
    'portsmouth',
    'powys',
    'reading',
    'redcar and cleveland',
    'renfrew(shire)?',
    'rhondda cynon taff?',
    'rochdale',
    'rotherham',
    'rutland',
    'salford',
    'sandwell',
    'scottish borders',
    'sefton',
    'sheffield',
    'shetland islands',
    'shrop(shire)?',
    'sir benfro',
    'sir ceredigion',
    'sir ddinbych',
    'sir fynwy',
    'sir gaerfyrddin',
    'sir y fflint',
    'sir ynys mon',
    'slough',
    'solihull',
    'somerset',
    'southampton',
    'southend-on-sea',
    'st helens',
    'stafford(shire)?',
    'stirling',
    'stockport',
    'stockton-on-tees',
    'stoke-on-trent',
    'suffolk',
    'sunderland',
    'surrey',
    'sussex',
    'swansea',
    'swindon',
    'tameside',
    'telford and wrekin',
    'thurrock',
    'tor-faen',
    'torbay',
    'torfaen',
    'trafford',
    'tyne and wear',
    'tyneside',
    'vale of glamorgan',
    'wakefield',
    'walsall',
    'warrington',
    'warwick(shire)?',
    'wigan',
    'wilt(shire)?',
    'windsor and maidenhead',
    'wirral',
    'wokingham',
    'wolverhampton',
    'worcester(shire)?',
    'wrecsam',
    'wrexham',
    'york',
    'york(shire)?',
  ]
  
  county_names = '('+county_names_list.join('|')+')'  
  county_suffix_re = Regexp.new(S2C_WHITESPACE+county_names+S2C_WHITESPACE+'?$', Regexp::IGNORECASE)  
  if county_suffix_re.match(address)
    return true
  end

  post_code = '[A-Z][A-Z]?[0-9R][0-9A-Z]? ?[0-9][A-Z]{2}'
  
  post_code_suffix_re = Regexp.new(S2C_WHITESPACE+post_code+S2C_WHITESPACE+'?$', Regexp::IGNORECASE)  
  if post_code_suffix_re.match(address)
    return true
  end

  return false
end

# Does the actual conversion of the US address string into coordinates
def geocode_us_address(address)
  locations = $geocoder_db.geocode(address, true)
  if locations and locations.length>0
    location = locations[0]
    if location[:number] and location[:street]
      street_address = location[:number]+' '+location[:street]
    else
      street_address = ''
    end
    info = {
      :latitude => location[:lat],
      :longitude => location[:lon],
      :country_code => 'US',
      :country_code3 => 'USA',
      :country_name => 'United States',
      :region => location[:state],
      :locality => location[:city],
      :street_address => street_address,
      :street_number => location[:number],
      :street_name => location[:street],
      :confidence => location[:score],
      :fips_county => location[:fips_county]
    }
  else
    info = nil
  end
  
  info
end

# Does the actual conversion of the UK address string into coordinates
def geocode_uk_address(address, conn)

  whitespace_re = Regexp.new(S2C_WHITESPACE)
  clean_address = address.gsub(whitespace_re, ' ')

  s2c_debug_log("clean_address='%s'" % clean_address.inspect)

  post_code_re = Regexp.new('( |^)([A-Z][A-Z]?[0-9R][0-9A-Z]?) ?([0-9][A-Z]{2})( |$)', Regexp::IGNORECASE)
  s2c_debug_log("post_code_re='%s'" % post_code_re.inspect)
  post_code_match = post_code_re.match(clean_address)
  s2c_debug_log("post_code_match='%s'" % post_code_match.inspect)
  if post_code_match
  
    clean_address = clean_address[0..post_code_match.begin(0)]
  
    # Right-pad it with spaces to match the database format
    first_part = post_code_match[2].to_s.ljust(4, ' ')
    second_part = post_code_match[3].to_s
    
    full_post_code = first_part+second_part
  
    post_code_select = 'SELECT postcode,country_code,county_code,district_code,ward_code'+
      ',ST_Y(location::geometry) as latitude, ST_X(location::geometry) AS longitude'+
      ' FROM "uk_postcodes" WHERE postcode=\''+full_post_code+'\' LIMIT 1;'

    s2c_debug_log("post_code_select='%s'" % post_code_select)

    post_code_hashes = select_as_hashes(conn, post_code_select)

    s2c_debug_log("post_code_hashes='%s'" % post_code_hashes.inspect)
  
    if post_code_hashes and post_code_hashes.length>0
    
      post_code_info = post_code_hashes[0]

      district_code = post_code_info['county_code']+post_code_info['district_code']
      district_select = 'SELECT * FROM uk_district_names WHERE district_code=\''+district_code+'\';'
      s2c_debug_log("district_select='%s'" % district_select.inspect)
      district_hashes = select_as_hashes(conn, district_select)
      s2c_debug_log("district_hashes='%s'" % district_hashes.inspect)
      district_info = district_hashes[0]
      district_name = district_info['name']
      
      ward_code = district_code+post_code_info['ward_code']
      ward_select = 'SELECT * FROM uk_ward_names WHERE ward_code=\''+ward_code+'\';'
      s2c_debug_log("ward_select='%s'" % ward_select.inspect)
      ward_hashes = select_as_hashes(conn, ward_select)
      s2c_debug_log("ward_hashes='%s'" % ward_hashes.inspect)
      ward_info = ward_hashes[0]
      ward_name = ward_info['name']
      
      info = {
        :latitude => post_code_info['latitude'],
        :longitude => post_code_info['longitude'],
        :country_code => 'UK',
        :country_code3 => 'GBR',
        :country_name => 'United Kingdom',
        :region => district_name,
        :locality => ward_name,
        :street_address => nil,
        :street_number => nil,
        :street_name => nil,
        :confidence => 9,
        :fips_county => nil
      }

      s2c_debug_log("Updating info to '%s' for '%s'" % [info.inspect, full_post_code])
            
    end
    
  end

  clean_address.gsub!(/ (U\.?K\.?|United Kingdom|Great Britain|England|Scotland|Wales) *$/i, '')

  s2c_debug_log("clean_address='%s'" % clean_address.inspect)
  
  # See if we can break up the address into obvious street and other sections
  street_markers_list = [
    'Way',
    'Street',
    'St',
    'Drive',
    'Dr',
    'Avenue',
    'Ave',
    'Av',
    'Court',
    'Ct',
    'Terrace',
    'Road',
    'Rd',
    'Lane',
    'Ln',
    'Place',
    'Pl',
    'Boulevard',
    'Blvd',
    'Highway',
    'Hwy',
    'Crescent',
    'Row',
    'Rw',
    'Mews',
  ]
  
  street_marker = '('+street_markers_list.join('|')+')'

  street_parts_re = Regexp.new('^(.*[a-z]+.*'+street_marker+')(.*)', Regexp::IGNORECASE)
  street_parts_match = street_parts_re.match(clean_address)
  s2c_debug_log("street_parts_match='%s'" % street_parts_match.inspect)
  if street_parts_match
    street_string = street_parts_match[1]
    place_string = street_parts_match[3]
  else
    street_string = nil
    place_string = clean_address
  end
  
  # Now try to extract the village/town/county parts
  # See http://wiki.openstreetmap.org/wiki/Key:place
  place_ranking = {
    'county' => 0,
    'island' => 1,
    'city' => 2,
    'town' => 3,
    'suburb' => 4,
    'village' => 5,
    'hamlet' => 6,
    'isolated_dwelling' => 6,
    'locality' => 6,
    'islet' => 6,
    'farm' => 6,
  }
  
  place_parts = place_string.strip.split(' ').reverse
  unrecognized_parts = []

  s2c_debug_log("place_parts='%s'" % place_parts.inspect)

  parts_count = [place_parts.length, 4].min
  
  while place_parts.length > 0 do
  
    if parts_count < 1
      unrecognized_token = place_parts.shift(1)
      s2c_debug_log("unrecognized_token '%s'" % unrecognized_token)
      unrecognized_parts.push(unrecognized_token)
      parts_count = [place_parts.length, 4].min
    end
  
    candidate_name = place_parts[0..(parts_count-1)].reverse.join(' ')
    parts_count -= 1

    s2c_debug_log("candidate_name='%s'" % candidate_name)
    s2c_debug_log("parts_count='%d'" % parts_count)

    location_select = 'SELECT name,place'+
      ',ST_Y(way::geometry) as latitude, ST_X(way::geometry) AS longitude'+
      ' FROM "uk_osm_point" WHERE lower(name)=lower(\''+candidate_name+'\');'

    s2c_debug_log("location_select='%s'" % location_select.inspect)

    location_hashes = select_as_hashes(conn, location_select)
  
    if !location_hashes or location_hashes.length == 0
      s2c_debug_log("No matches found for '%s'" % candidate_name)
      next
    end
  
    # Rank the results either by the size of the area they represent, or their distance
    # from other identified parts of the address if any have been found
    candidate_hashes = []
    location_hashes.each do |location_hash|
    
      place = location_hash['place']
      
      # If we don't recognize this place type, skip it
      if !place_ranking.has_key?(place)
        s2c_debug_log("Unknown place '%s' found for '%s'" % [place, candidate_name])
        next
      end
      
      candidate_confidence = place_ranking[place]
    
      # We've already found a place, so use that as a reference
      if info      
        # Get an approximate distance measure. This is pretty distorted, but workable
        # as a scoring mechanism
        delta_lat = info[:latitude].to_f-location_hash['latitude'].to_f
        delta_lon = info[:longitude].to_f-location_hash['longitude'].to_f
        score = (delta_lat*delta_lat) + (delta_lon*delta_lon)
      else
        score = place_ranking[place]
      end
      
      candidate_hashes.push({
        :name => location_hash['name'],
        :latitude => location_hash['latitude'],
        :longitude => location_hash['longitude'],
        :place => place,
        :score => score,
        :confidence => candidate_confidence,
      })
      
    end
  
    # No valid locations with valid place types were found, so move along
    if candidate_hashes.length == 0
      s2c_debug_log("No valid matches found for '%s'" % candidate_name)
      next
    end
    
    sorted_candidates = candidate_hashes.sort do |a,b| a[:score]<=>b[:score] end

    top_candidate = sorted_candidates[0]
    
    # Now try to update what we know with the new information
    if !info
      info = {
        :latitude => nil,
        :longitude => nil,
        :country_code => 'UK',
        :country_code3 => 'GBR',
        :country_name => 'United Kingdom',
        :region => nil,
        :locality => nil,
        :street_address => nil,
        :street_number => nil,
        :street_name => nil,
        :confidence => -1,
        :fips_county => nil
      }
    end
    
    old_confidence = info[:confidence]
    candidate_confidence = top_candidate[:confidence]
    if candidate_confidence > old_confidence
      
      info[:latitude] = top_candidate[:latitude]
      info[:longitude] = top_candidate[:longitude]
      info[:confidence] = candidate_confidence

      name = top_candidate[:name]
      place = top_candidate[:place]
      if place == 'county'
        info[:region] = name
      else
        info[:locality] = name
      end

      s2c_debug_log("Updating info to '%s' for '%s'" % [info.inspect, candidate_name])
  
    end
    
    # Remove the matched parts, and start matching anew on the remainder
    place_parts.shift(parts_count+1)
    parts_count = [place_parts.length, 4].min
    unrecognized_parts = []  

  end

  unrecognized_prefix = unrecognized_parts.reverse.join(' ')
  
  s2c_debug_log("unrecognized_prefix='%s'" % unrecognized_prefix)
  
  if !street_string
    street_string = unrecognized_prefix.strip
  end
  
  # If we found a general location, see if we can narrow it down using the street
  if info and street_string and street_string.length > 0
  
    street_string = canonicalize_street_string(street_string)
    street_parts = street_string.strip.split(' ').reverse

    s2c_debug_log("street_parts='%s'" % street_parts.inspect)

    parts_count = [street_parts.length, 4].min
    
    while street_parts.length > 0 do
    
      if parts_count < 1
        unrecognized_token = street_parts.shift(1)
        s2c_debug_log("unrecognized_token '%s'" % unrecognized_token)
        parts_count = [street_parts.length, 4].min
      end
    
      candidate_name = street_parts[0..(parts_count-1)].reverse.join(' ')
      parts_count -= 1

      s2c_debug_log("candidate_name='%s'" % candidate_name)
      s2c_debug_log("parts_count='%d'" % parts_count)

      point_string = 'setsrid(makepoint('+PGconn.escape(info[:longitude])+', '+PGconn.escape(info[:latitude])+'), 4326)'

      distance = 0.1
      road_select = 'SELECT name'+
        ',ST_Y(ST_line_interpolate_point(way,ST_line_locate_point(way,'+point_string+'))::geometry) AS latitude,'+
        ' ST_X(ST_line_interpolate_point(way,ST_line_locate_point(way,'+point_string+'))::geometry) AS longitude'+
        ' FROM "uk_osm_line" WHERE lower(name)=lower(\''+candidate_name+'\')'+
        ' AND ST_DWithin('+
        point_string+
        ', way, '+
        distance.to_s+
        ') ORDER BY ST_Distance('+
        point_string+
        ', way) LIMIT 1;'

      s2c_debug_log("road_select='%s'" % road_select.inspect)

      road_hashes = select_as_hashes(conn, road_select)
    
      if !road_hashes or road_hashes.length == 0
        s2c_debug_log("No matches found for '%s'" % candidate_name)
        next
      end
    
      top_candidate = road_hashes[0]
        
      info[:latitude] = top_candidate['latitude']
      info[:longitude] = top_candidate['longitude']
      info[:confidence] = [info[:confidence], 8].max
      info[:street_name] = top_candidate['name']

      # Remove the matched parts
      street_parts.shift(parts_count+1)
      unrecognized_street = street_parts.reverse.join(' ')
      
      street_number = /\d+[a-z]?/i.match(unrecognized_street)
      if street_number
        info[:street_number] = street_number.to_s
        info[:street_address] = info[:street_number]+' '+info[:street_name]
      end

      s2c_debug_log("Updating info to '%s' for '%s'" % [info.inspect, candidate_name])
    
      # We've found a street, so stop looking
      break
    end

    s2c_debug_log("unrecognized_street='%s'" % unrecognized_street)    
  
  end

  info
end

def canonicalize_street_string(street_string)

  output = street_string

  abbreviation_mappings = {
    'Street' => ['St'],
    'Drive' => ['Dr'],
    'Avenue' => ['Ave', 'Av'],
    'Court' => ['Ct'],
    'Road' => ['Rd'],
    'Lane' => ['Ln'],
    'Place' => ['Pl'],
    'Boulevard' => ['Blvd'],
    'Highway' => ['Hwy'],
    'Row' => ['Rw'],
  }
  
  abbreviation_mappings.each do |canonical, abbreviations|
  
    abbreviations_re = Regexp.new('^(.*[a-z]+.*)('+abbreviations.join('|')+')([^a-z]*)$', Regexp::IGNORECASE)
    output.gsub!(abbreviations_re, '\1'+canonical+'\3')
  
  end

  output
end