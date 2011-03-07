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
require 'sinatra'

# Some hackiness to include the library script, even if invoked from another directory
require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'geodict_lib')

enable :run

# Utility functions

# Pulls a request argument if it's been specified, otherwise uses the default
def get_or_default(hash, key, default)

  if hash.has_key?(key)
    hash[key]
  else
    default
  end
end

# Returns an error code and message, and then exits
def fatal_error(message, output_format = 'xml', code = 500)

  if output_format == 'xml'
    content = '<?xml version="1.0" encoding="utf-8"?><error>'+message+'</error>'
  elsif output_format == 'json'
    content = { :error => message }.to_json
  else
    content = message
  end

  halt code, content

end

# Converts a Geodict symbol for a type of place into a Yahoo string
def convert_geodict_to_yahoo_type(geodict_type)
  if geodict_type == :COUNTRY
    'Country'
  elsif geodict_type == :REGION
    'Region'
  elsif geodict_type == :CITY
    'Town'
  else
    fatal_error('Internal error - bad Geodict place type "'+geodict_type+'"')
  end

end

# Methods to directly serve up content

# The main page.
get '/' do

  <<-HTML
  <html>
    <head>
      <title>Test</title>
    </head>
    <body>
      Test page
    </body>
  </html>
  HTML

end

# Emulates the interface to Yahoo's Placemaker API
# See http://developer.yahoo.com/geo/placemaker/guide/web-service.html for documentation
post '/v1/document' do

  puts params.inspect

  input_language = get_or_default(params, 'inputLanguage', 'en-US')
  output_type = get_or_default(params, 'outputType', 'xml')
  callback = get_or_default(params, 'callback', nil)
  document_content = get_or_default(params, 'documentContent', nil)
  document_title = get_or_default(params, 'documentTitle', nil)
  document_url = get_or_default(params, 'documentURL', nil)
  document_type = get_or_default(params, 'documentType', 'text/plain')
  auto_disambiguate = get_or_default(params, 'autoDisambiguate', true)
  focus_woeid = get_or_default(params, 'focusWoeId', nil)
  confidence = get_or_default(params, 'confidence', '8')
  character_limit = get_or_default(params, 'character_limit', nil)
  app_id = get_or_default(params, 'appid', nil)

  # Only a subset of Yahoo's functionality is supported, so check to make sure the
  # client isn't requesting anything we can't handle.
  if input_language != 'en-US'
    fatal_error('Unsupported inputLanguage: "'+input_language+'"', output_type, 500)
  end

  if output_type != 'xml'
    fatal_error('Unsupported outputType: "'+output_type+'"', output_type, 500)
  end

  if !document_content and !document_url
    fatal_error('You must specify either a documentContent or a documentURL parameter', output_type, 500)
  end

  if document_url
    fatal_error('The documentURL method of grabbing content is not yet supported', output_type, 500)
  end

  if document_type != 'text/plain'
    fatal_error('Unsupported documentType: "'+document_type+'"', output_type, 500)
  end

  # Start timing how long this all takes
  processing_start_time = Time.now

  # Grab the input content
  if document_type == 'text/plain'
    input_text = document_content
  end

  # Run the location extraction process
  locations = find_locations_in_text(input_text)

  # Calculate the elapsed time for processing
  processing_end_time = Time.now
  processing_duration = processing_end_time-processing_start_time

  if output_type == 'xml'

    result = <<-XML
<?xml version="1.0" encoding="utf-8"?>
  <contentlocation
    xmlns:yahoo="http://www.yahooapis.com/v1/base.rng"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns="http://wherein.yahooapis.com/v1/schema"
    xml:lang="en">
    XML
    
    result += '  <processingTime>'+processing_duration.to_s+'</processingTime>'+"\n"
    result += '  <version>Geodict build 000000</version>'+"\n"
    result += '  <documentLength>'+input_text.length.to_s+'</documentLength>'+"\n"
    
    result += '  <document>'+"\n"
    
    # Make sure we return at least one location, even if it's bogus
    if locations.length == 0
      locations = [{:found_tokens=>[{
        :type => :COUNTRY,
        :lat => 0,
        :lon => 0,
        :start_index => 0,
        :end_index => 1,
        :code => 'NA',
        :matched_string => '?'
      }]}]
    end

    yahoo_locations = []
    locations.each_with_index do |location_info, index|
      location = location_info[:found_tokens][0]
      yahoo_locations.push({
        # We don't have the actual WOEID, so just create a locally-unique ID
        :woeid => index.to_s,
        :yahoo_type => convert_geodict_to_yahoo_type(location[:type]),
        :name => location[:matched_string],
        :lat => location[:lat].to_s,
        :lon => location[:lon].to_s,
        :start_index => location[:start_index].to_s,
        :end_index => location[:end_index].to_s,
      })
    end
    
    first_location = yahoo_locations[0]
    
    result += <<-XML
    <administrativeScope>
      <woeId>#{first_location[:woeid]}</woeId>
      <type>#{first_location[:yahoo_type]}</type>
      <name><![CDATA[#{first_location[:name]}]]></name>
      <centroid>
        <latitude>#{first_location[:lat]}</latitude>
        <longitude>#{first_location[:lon]}</longitude>
      </centroid>
    </administrativeScope>
    <geographicScope>
      <woeId>#{first_location[:woeid]}</woeId>
      <type>#{first_location[:yahoo_type]}</type>
      <name><![CDATA[#{first_location[:name]}]]></name>
      <centroid>
        <latitude>#{first_location[:lat]}</latitude>
        <longitude>#{first_location[:lon]}</longitude>
      </centroid>
    </geographicScope>
    <extents>
      <center>
        <latitude>#{first_location[:lat]}</latitude>
        <longitude>#{first_location[:lon]}</longitude>
      </center>
      <southWest>
        <latitude>#{first_location[:lat]}</latitude>
        <longitude>#{first_location[:lon]}</longitude>
      </southWest>
      <northEast>
        <latitude>#{first_location[:lat]}</latitude>
        <longitude>#{first_location[:lon]}</longitude>
      </northEast>
    </extents>
    XML
    
    yahoo_locations.each do |location|
      result += <<-XML
    <placeDetails>
      <place>
        <woeId>#{location[:woeid]}</woeId>
        <type>#{location[:yahoo_type]}</type>
        <name><![CDATA[#{location[:name]}]]></name>
        <centroid>
          <latitude>#{location[:lat]}</latitude>
          <longitude>#{location[:lon]}</longitude>
        </centroid>
      </place>
      <matchType>0</matchType>
      <weight>1</weight>
      <confidence>10</confidence>
    </placeDetails>
      XML
    end
    
    result += '    <referenceList>'+"\n"
    yahoo_locations.each do |location|
      result += <<-XML
      <reference>
        <woeIds>#{location[:woeid]}</woeIds>
        <start>#{location[:start_index]}</start>
        <end>#{location[:end_index]}</end>
        <isPlaintextMarker>1</isPlaintextMarker>
        <text><![CDATA[#{location[:name]}]]></text>
        <type>plaintext</type>
        <xpath><![CDATA[]]></xpath>
      </reference>
      XML
    end

    result += '    </referenceList>'+"\n"

    result += <<-XML
  </document>
</contentlocation>
    XML
  
  end

  return result
  
end