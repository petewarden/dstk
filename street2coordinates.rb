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

# Takes an array of postal addresses as input, and looks up their locations using
# data from the US census
def street2coordinates(addresses)

  if !$geocoder_db
    $geocoder_db = Geocoder::US::Database.new('../geocoderdata/geocoder.db', {:debug => false})
  end

  conn = PGconn.connect(DSTKConfig::HOST, DSTKConfig::PORT, '', '', DSTKConfig::REVERSE_GEO_DATABASE, DSTKConfig::USER, DSTKConfig::PASSWORD)

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
  
  zip_code = '\d\d\d\d\d'
  
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
    info = {
      :latitude => location[:lat],
      :longitude => location[:lon],
      :country_code => 'US',
      :country_code3 => 'USA',
      :country_name => 'United States',
      :region => location[:state],
      :locality => location[:city],
      :street_address => location[:number]+' '+location[:street],
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

  tokens = address.split(Regexp.new(S2C_WHITESPACE))
  
  clean_address = tokens.join(' ')

  post_code_re = RegExp.new('([A-Z][A-Z]?[0-9R][0-9A-Z]?) ?([0-9][A-Z]{2})')
  post_code_match = post_code_re.match(clean_address)
  if post_code_match
  
    first_part = post_code_match[1].to_s
    if first_part.length == 3
      first_part += ' '
    end
    second_part = post_code_match[2].to_s
    
    full_post_code = first_part+second_part
  
    post_code_select = 'SELECT postcode,country_code,county_code,district_code,ward_code'+
      ',ST_Y(location::geometry) as latitude, ST_X(location::geometry) AS longitude'+
      ' FROM "uk_postcodes" WHERE postcode=\''+full_post_code+'\' LIMIT 1;'

    post_code_hashes = select_as_hashes(conn, uk_select)
  
    if post_code_hashes and post_code_hashes.length>0
    
      post_code_info = post_code_hashes[0]

      district_code = post_code_info['district_code']
      district_select = 'SELECT * FROM uk_district_names WHERE district_code=\''+district_code+'\';'
      district_hashes = select_as_hashes(conn, district_select)
      district_info = district_hashes[0]
      district_name = district_info['name']
      
      ward_code = post_code_info['ward_code']
      ward_select = 'SELECT * FROM uk_ward_names WHERE ward_code=\''+ward_code+'\';'
      ward_hashes = select_as_hashes(conn, ward_select)
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
          
    end
    
  end

  info
end