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

# Keep a singleton accessor for the geocoder object, so we don't leak resources
# Fix for https://github.com/petewarden/dstk/issues/4
$geocoder_db = nil

# Takes an array of postal addresses as input, and looks up their locations using
# data from the US census
def street2coordinates(addresses)

  if !$geocoder_db
    $geocoder_db = Geocoder::US::Database.new('../geocoderdata/geocoder.db', {:debug => false})
  end

  output = {}
  addresses.each do |address|
    begin
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
    rescue
      printf(STDERR, $!.inspect + $@.inspect + "\n")
      info = nil
    end
    output[address] = info
  end
    
  return output

end
