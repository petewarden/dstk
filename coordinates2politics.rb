#***********************************************************************************
#
# All code (C) Pete Warden, 2011
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
#
#***********************************************************************************

require 'rubygems' if RUBY_VERSION < '1.9'

require 'json'

cwd = File.expand_path(File.dirname(__FILE__))
require File.join(cwd, 'geodict_lib')
require File.join(cwd, 'dstk_config')

TypeToFriendly = {
  'admin2' => 'country',
  'admin4' => 'state',
  'admin6' => 'county',
  'admin5' => 'city',
  'admin8' => 'city'  
}

# Takes an array of coordinates as input, and looks up what political areas they lie
# within
def coordinates2politics(locations, callback=nil)

  result = []
  locations.each do |location|

    lat = location[:latitude]
    lon = location[:longitude]
    
    lat_s = PGconn.escape(lat.to_s)
    lon_s = PGconn.escape(lon.to_s)
    
    is_valid = true
    if !lat_s or lat_s.length == 0 or !lon_s or lon_s.length == 0
      is_valid = false
    end
    
    if is_valid
      point_string = 'setsrid(makepoint(' + lon_s + ', ' + lat_s +'), 4326)'
      country_select = 'SELECT name,country_code FROM "world_countries_polygon" WHERE ST_DWithin('+point_string+', way, 0.1);'
      country_hashes = select_as_hashes(country_select, DSTKConfig::REVERSE_GEO_DATABASE)
      if !country_hashes or country_hashes.length == 0
        is_valid = false
      end
    end
    
    if !is_valid
      output = nil
    else
    
      output = []
      country_hashes.each do |country_hash|
      
        country_name = country_hash['name']
        country_code = country_hash['country_code'].downcase
      
        output.push({
          :name => country_name,
          :code => country_code,
          :type => 'admin2',
          :friendly_type => 'country'
        })

        area_select = 'SELECT name,code,type FROM "admin_areas_polygon" WHERE ST_DWithin('+point_string+', way, 0.01);'

        area_hashes = select_as_hashes(area_select, DSTKConfig::REVERSE_GEO_DATABASE)
        if area_hashes
        
          area_hashes.each do |area_hash|
            area_name = area_hash['name']
            area_code = area_hash['code'].downcase
            area_type = area_hash['type']
            if TypeToFriendly.has_key?(area_type)
              friendly_type = TypeToFriendly[area_type]
            else
              friendly_type = area_type
            end
            output.push({
              :name => area_name,
              :code => area_code,
              :type => area_type,
              :friendly_type => friendly_type
            })
          end
        
        end
        
        # Look in the neighborhoods table if we're in the US
        if country_code == 'usa'
          neighborhood_select = 'SELECT name,city,state FROM "neighborhoods_polygon" WHERE ST_DWithin('+point_string+', way, 0.0001);'

          neighborhood_hashes = select_as_hashes(neighborhood_select, DSTKConfig::REVERSE_GEO_DATABASE)
          if neighborhood_hashes
          
            neighborhood_hashes.each do |neighborhood_hash|
              neighborhood_name = neighborhood_hash['name']
              neighborhood_city = neighborhood_hash['city']
              neighborhood_state = neighborhood_hash['state']
              neighborhood_type = 'neighborhood'
              friendly_type = 'neighborhood'
              neighborhood_code = neighborhood_name+'|'+neighborhood_city+'|'+neighborhood_state

              output.push({
                :name => neighborhood_name,
                :code => neighborhood_code,
                :type => neighborhood_type,
                :friendly_type => friendly_type
              })
            end
                    
          end
        
        elsif country_code == 'eng' or country_code == 'sct' or country_code == 'wls'
        
          distance = 0.01
          uk_hashes = nil
          while distance < 1.0 and !uk_hashes do
        
            uk_select = 'SELECT postcode,country_code,nhs_region_code,nhs_code,county_code,district_code,ward_code,location'+
              ' FROM "uk_postcodes" WHERE ST_DWithin('+
              point_string+
              ', location, '+
              distance.to_s+
              ') ORDER BY ST_Distance('+
              point_string+
              ', location) LIMIT 1;'

            uk_hashes = select_as_hashes(uk_select, DSTKConfig::REVERSE_GEO_DATABASE)
              
            distance *= 2
          end

          if uk_hashes
          
            uk_hashes.each do |uk_hash|
              postal_code = uk_hash['postcode']
              nhs_code = uk_hash['nhs_region_code']+uk_hash['nhs_code']
              ward_code = uk_hash['county_code']+uk_hash['district_code']+uk_hash['ward_code'] 
              
              ward_select = 'SELECT * FROM uk_ward_names WHERE ward_code=\''+ward_code+'\';'
              ward_hashes = select_as_hashes(ward_select, DSTKConfig::REVERSE_GEO_DATABASE)
              ward_info = ward_hashes[0]
              ward_name = ward_info['name']
              
              output.push({
                :name => postal_code,
                :code => postal_code,
                :type => 'postal_code',
                :friendly_type => 'postal code'
              })

              output.push({
                :name => nhs_code,
                :code => nhs_code,
                :type => 'uk_nhs_area',
                :friendly_type => 'nhs area'
              })

              output.push({
                :name => ward_name,
                :code => ward_code,
                :type => 'admin10',
                :friendly_type => 'council ward'
              })
          
            end
          
          end
        
        end
      
      end
    
    end
    
    result.push({
      :location => location,
      :politics => output
    })
  
  end

  result
  
end

if __FILE__ == $0
  
  locations = [ {:latitude => "37.769456", :longitude => "-122.429128"} ]
  $stderr.puts "locations=#{JSON.pretty_generate(locations)}"
  politics = coordinates2politics(locations)
  $stderr.puts "politics=#{JSON.pretty_generate(politics)}"

end