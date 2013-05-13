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

AVAILABLE_STATISTICS = {
  'population_density' => {
    'description' => 'The number of inhabitants per square kilometer around this point.',
    'source_name' => 'NASA Socioeconomic Data and Applications Center (SEDAC) – Hosted by CIESIN at Columbia University',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/set/gpw-v3-population-density',
  },
  'land_cover' => {
    'description' => 'What type of environment exists around this point - urban, water, vegetation, mountains, etc',
    'source_name' => 'European Commission Land Resource Management Unit Global Land Cover 2000',
    'source_url' => 'http://bioval.jrc.ec.europa.eu/products/glc2000/products.php',
    'translation_table' => {
      1 => 'Tree Cover, broadleaved, evergreen',
      2 => 'Tree Cover, broadleaved, deciduous, closed',
      3 => 'Tree Cover, broadleaved, deciduous, open',
      4 => 'Tree Cover, needle-leaved, evergreen',
      5 => 'Tree Cover, needle-leaved, deciduous',
      6 => 'Tree Cover, mixed leaf type',
      7 => 'Tree Cover, regularly flooded, fresh',
      8 => 'Tree Cover, regularly flooded, saline, (daily variation)',
      9 => 'Mosaic: Tree cover / Other natural vegetation',
      10 => 'Tree Cover, burnt',
      11 => 'Shrub Cover, closed-open, evergreen',
      12 => 'Shrub Cover, closed-open, deciduous',
      13 => 'Herbaceous Cover, closed-open',
      14 => 'Sparse Herbaceous or sparse shrub cover',
      15 => 'Regularly flooded shrub and/or herbaceous cover',
      16 => 'Cultivated and managed areas',
      17 => 'Mosaic: Cropland / Tree Cover / Other Natural Vegetation',
      18 => 'Mosaic: Cropland / Shrub and/or Herbaceous cover',
      19 => 'Bare Areas',
      20 => 'Water Bodies',
      21 => 'Snow and Ice',
      22 => 'Artificial surfaces and associated areas',
      23 => 'No data',
    },
  },
  'elevation' => {
    'description' => 'The height of the surface above sea level at this point.',
    'source_name' => 'NASA and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://srtm.csi.cgiar.org/',
    'units' => 'meters',
  },
  'mean_temperature' => {
    'description' => 'The mean monthly temperature at this point.',
    'source_name' => 'WorldClim',
    'source_url' => 'http://worldclim.org/',
    'frequency' => 12,
    'units' => 'degrees Celsius',
    'scale' => 0.1,
  },
  'precipitation' => {
    'description' => 'The monthly average total precipitation at this point.',
    'source_name' => 'WorldClim',
    'source_url' => 'http://worldclim.org/',
    'frequency' => 12,
    'units' => 'millimeters',
  },
  'us_population_under_one_year_old' => {
    'description' => 'The proportion of residents under one year of age.',
    'table' => 'usa100',
    'divide_by' => 'us_population',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_population_one_to_four_years_olds' => {
    'description' => 'The proportion of residents aged one to four years old.',
    'table' => 'usa200',
    'divide_by' => 'us_population',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_population_five_to_seventeen_years_old' => {
    'description' => 'The proportion of residents aged five to seventeen years old.',
    'table' => 'usa300',
    'divide_by' => 'us_population',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_population_eighteen_to_twenty_four_years_old' => {
    'description' => 'The proportion of residents aged eighteen to twenty four years old.',
    'table' => 'usa400',
    'divide_by' => 'us_population',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_population_twenty_five_to_sixty_four_years_old' => {
    'description' => 'The proportion of residents aged twenty five to sixty four years old.',
    'table' => 'usa500',
    'divide_by' => 'us_population',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_population_sixty_five_to_seventy_nine_years_old' => {
    'description' => 'The proportion of residents aged sixty five to seventy nine years old.',
    'table' => 'usa600',
    'divide_by' => 'us_population',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_population_over_seventy_nine_years_old' => {
    'description' => 'The proportion of residents over seventy nine years old.',
    'table' => 'usa700',
    'divide_by' => 'us_population',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_sample_area' => {
    'description' => 'The total area of the grid cell US Census samples were calculated on',
    'table' => 'usarea00',
    'units' => 'square meters',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_population_asian' => {
    'description' => 'The proportion of residents identifying as Asian.',
    'table' => 'usas00',
    'divide_by' => 'us_population',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_population_bachelors_degree' => {
    'description' => 'The proportion of residents whose maximum educational attainment was a bachelor\'s degree.',
    'table' => 'usba00',
    'divide_by' => 'us_population',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_population_black_or_african_american' => {
    'description' => 'The proportion of residents identifying as black or African American.',
    'table' => 'usbl00',
    'divide_by' => 'us_population',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_population_foreign_born' => {
    'description' => 'The proportion of residents who were born in a different country.',
    'table' => 'usfb00',
    'divide_by' => 'us_population',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_households_single_mothers' => {
    'description' => 'The proportion of households with a female householder, no husband, and one or more children under eighteen.',
    'table' => 'usfem00',
    'divide_by' => 'us_households',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_housing_units_after_1990' => {
    'description' => 'The proportion of housing units built after 1990.',
    'table' => 'usha100',
    'divide_by' => 'us_housing_units',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_housing_units_1970_to_1989' => {
    'description' => 'The proportion of housing units built between 1970 and 1989.',
    'table' => 'usha200',
    'divide_by' => 'us_housing_units',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_housing_units_1950_to_1969' => {
    'description' => 'The proportion of housing units built between 1950 and 1969.',
    'table' => 'usha300',
    'divide_by' => 'us_housing_units',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_housing_units_before_1950' => {
    'description' => 'The proportion of housing units built before 1950.',
    'table' => 'usha400',
    'divide_by' => 'us_housing_units',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_households' => {
    'description' => 'The number of households in this area.',
    'table' => 'ushh00',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_population_hispanic_or_latino' => {
    'description' => 'The proportion of residents who identify themselves as hispanic or latino.',
    'table' => 'ushi00',
    'divide_by' => 'us_population',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_housing_units' => {
    'description' => 'The total number of housing units in this area',
    'table' => 'ushu00',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_housing_units_one_person' => {
    'description' => 'The proportion of housing units containing only one person',
    'table' => 'ushu1p00',
    'divide_by' => 'us_housing_units',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_housing_units_no_vehicle' => {
    'description' => 'The proportion of occupied housing units with no vehicle available.',
    'table' => 'ushunv00',
    'divide_by' => 'us_housing_units',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_households_linguistically_isolated' => {
    'description' => 'The proportion of households in which no one aged 14 or older speaks English very well',
    'table' => 'usliso00',
    'divide_by' => 'us_households',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_population_low_income' => {
    'description' => 'The proportion of residents who earn less than twice the poverty level',
    'table' => 'uslowi00',
    'divide_by' => 'us_population',
  },
  'us_population_black_or_african_american_not_hispanic' => {
    'description' => 'The proportion of residents who didn\'t identify as hispanic or latino, just black or African American alone',
    'table' => 'usnhb00',
    'divide_by' => 'us_population',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_population_white_not_hispanic' => {
    'description' => 'The proportion of residents who didn\'t identify as hispanic or latino, just white alone',
    'table' => 'usnhw00',
    'divide_by' => 'us_population',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_housing_units_occupied' => {
    'description' => 'The proportion of housing units that are occupied.',
    'table' => 'usocc00',
    'divide_by' => 'us_housing_units',
  },
  'us_housing_units_owner_occupied' => {
    'description' => 'The proportion of housing units that are occupied by their owners.',
    'table' => 'usown00',
    'divide_by' => 'us_housing_units',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_population_native_hawaiian_and_other_pacific_islander' => {
    'description' => 'The proportion of residents who identify as Native Hawaiian or other Pacific islander.',
    'table' => 'uspi00',
    'divide_by' => 'us_population',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_population' => {
    'description' => 'The number of residents in this area',
    'table' => 'uspop00',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_population_poverty' => {
    'description' => 'The proportion of residents whose income is below the poverty level',
    'table' => 'uspov00',
    'divide_by' => 'us_population',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_housing_units_vacation' => {
    'description' => 'The number of vacant housing units that are used for seasonal, recreational, or occasional use.',
    'table' => 'ussea00',
    'divide_by' => 'us_housing_units',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_population_severe_poverty' => {
    'description' => 'The proportion of residents whose income is below half the poverty level.',
    'table' => 'ussevp00',
    'divide_by' => 'us_population',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
  'us_population_white' => {
    'description' => 'The proportion of residents who identify themselves as white.',
    'table' => 'uswh00',
    'divide_by' => 'us_population',
    'source_name' => 'US Census and the CGIAR Consortium for Spatial Information',
    'source_url' => 'http://sedac.ciesin.columbia.edu/data/collection/usgrid/sets/browse',
  },
}

# Takes a pair of coordinates as input, and looks up statistics about each point
def coordinates2statistics(lat, lon, wanted = nil, callback=nil)

  if !wanted
    wanted = AVAILABLE_STATISTICS.keys
  end
  wanted_map = {}
  wanted.each do |statistic|
    if !AVAILABLE_STATISTICS[statistic]
      raise "coordinates2statistics - '#{statistic}' is not recognized, use one of #{AVAILABLE_STATISTICS.keys.join(', ')}"
    end
    wanted_map[statistic] = true
  end

  lat_s = PGconn.escape(lat.to_s)
  lon_s = PGconn.escape(lon.to_s)
  
  is_valid = true
  if !lat_s or lat_s.length == 0 or !lon_s or lon_s.length == 0
    raise "coordinates2statistics - input (#{lat}, #{lon}) couldn't be understood as latitude, longitude coordinates"
  end
  
  point_string = 'ST_SetSRID(ST_MakePoint(' + lon_s + ', ' + lat_s +'), 4236)'
  select_prefix = 'SELECT ST_Value(rast, ' + point_string + ') AS value FROM '
  select_suffix = ' WHERE ST_Intersects(rast, ' + point_string + ');'

  wanted_map.each do |statistic, value|
    info = AVAILABLE_STATISTICS[statistic]
    if info['divide_by']
      dependency = info['divide_by']
      wanted_map[dependency] = true
    end
  end

  result = {}
  wanted_map.keys.each do |statistic|
    info = AVAILABLE_STATISTICS[statistic]
    table = info['table'] || statistic
    if info['frequency']
      frequency = info['frequency']
      value = []
      (0...frequency).each do |offset|
        full_table_name = table + '_' + "%02d" % (offset + 1)
        select = select_prefix + full_table_name + select_suffix
        $stderr.puts select
        rows = select_as_hashes(select, DSTKConfig::STATISTICS_DATABASE)
        if !rows or rows.length < 1
          next
        end
        row = rows[0]
        value << row['value'].to_i
      end
    else
      select = select_prefix + table + select_suffix
      $stderr.puts select
      rows = select_as_hashes(select, DSTKConfig::STATISTICS_DATABASE)
      if !rows or rows.length < 1
        next
      end
      row = rows[0]
      value = row['value'].to_i
    end
    output = {
      'value' => value,
      'description' => info['description'],
      'source_name' => info['source_name'],
    }
    if info['units'] then output['units'] = info['units'] end
    result[statistic] = output
  end

  result.each do |statistic, output|
    info = AVAILABLE_STATISTICS[statistic]
    if info['divide_by']
      dependency_name = info['divide_by']
      dependency_result = result[dependency_name]
      dependency_value = dependency_result['value']
      raw_value = output['value']
      output['value'] = raw_value.to_f / dependency_value
      output['proportion_of'] = dependency_value
    elsif info['translation_table']
      translation_table = info['translation_table']
      raw_value = result[statistic]['value']
      translated_value = translation_table[raw_value]
      output['value'] = translated_value
      output['index'] = raw_value
    end
    if info['scale']
      scale = info['scale']
      if output['value'].length
        output['value'] = output['value'].map do |value| (value * scale) end
      else
        output['value'] = (output['value'] * scale)
      end
    end
  end

  result  
end

if __FILE__ == $0

  if ARGV.length > 0
    wanted = ARGV
  else
    wanted = nil
  end

  statistics = coordinates2statistics(52.315615, 0.013046, wanted)
  $stderr.puts "statistics=#{JSON.pretty_generate(statistics)}"

end