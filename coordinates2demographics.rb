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
require File.join(cwd, 'coordinates2politics')

ValueTypeToName = {
  '03' => :unemployment_rate,
  '04' => :unemployment,
  '05' => :employment,
  '06' => :labor_force,
}

# Takes an array of coordinates as input, and looks up what political areas they lie
# within
def coordinates2demographics(locations, callback=nil)

  politics_results = coordinates2politics(locations)

  conn = PGconn.connect(DSTKConfig::HOST, DSTKConfig::PORT, '', '', DSTKConfig::REVERSE_GEO_DATABASE, DSTKConfig::USER, DSTKConfig::PASSWORD)

  result = []
  politics_results.each do |politics_result|
    
    location = politics_result[:location]
    politics = politics_result[:politics]
    demographics = []
    
    code_for_type = {}
    politics.each do |area|
      type = area[:type]
      code = area[:code]
      code_for_type[type] = code
    end
    
    country_code = code_for_type['admin2']
    state_and_county_code = code_for_type['admin6']
    if country_code == 'usa' and state_and_county_code
      state_code, county_code = state_and_county_code.split('_', 2)
      unemployment_select = "SELECT * FROM us_county_unemployment WHERE state_code='#{state_code}' AND county_code='#{county_code}';"
      unemployment_hashes = select_as_hashes(conn, unemployment_select)
      if unemployment_hashes
        county_unemployment = {}
        ValueTypeToName.each do |value_type, value_name| county_unemployment[value_name] = [] end
        unemployment_hashes.each do |unemployment_hash|
          year = unemployment_hash['year']
          month = unemployment_hash['month']
          value_type = unemployment_hash['value_type']
          value = unemployment_hash['value']
          value_name = ValueTypeToName[value_type]
          county_unemployment[value_name] = [year, month, value]
        end
        demographics[:county_unemployment] = county_unemployment
      end
    end
    
    result.push({
      :location => location,
      :politics => politics,
      :demographics => demographics
    })
  
  end

  result
  
end


if __FILE__ == $0
  
  locations = [ {:latitude => 37.769456, :longitude => -122.429128} ]
  $stderr.puts "locations=#{JSON.pretty_generate(locations)}"
  demographics = coordinates2demographics(locations)
  $stderr.puts "demographics=#{JSON.pretty_generate(demographics)}"

end