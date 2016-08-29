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
require 'json'
require 'pg'
require 'hpricot'
require 'htmlentities'
require 'tempfile'
require 'csv'
# Rails deprecated the old ActiveSupport secure_random, so fall back to the
# standard library version if it's not present
begin
  require 'active_support/secure_random'
rescue LoadError
  require 'securerandom'
end

# Some hackiness to include the library script, even if invoked from another directory
cwd = File.expand_path(File.dirname(__FILE__))
require File.join(cwd, 'geodict_lib')
require File.join(cwd, 'dstk_config')
require File.join(cwd, 'cruftstripper')
require File.join(cwd, 'text2people')
require File.join(cwd, 'text2times')
require File.join(cwd, 'street2coordinates')
require File.join(cwd, 'coordinates2politics')
require File.join(cwd, 'emulategoogle')
require File.join(cwd, 'text2sentiment')
require File.join(cwd, 'coordinates2statistics')

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

# Returns a JSON representation of the hash, optionally wrapped in a callback
def make_json(hash, callback = nil)

  result = ''
  if callback
    result += callback+'('
  end
  result += JSON.pretty_generate(hash)
  if callback
    result += ');'
  end
  
  return result
end

# Returns an error code and message, and then exits
def fatal_error(message, output_format = 'xml', code = 500, callback = nil)

  if output_format == 'xml'
    content = '<?xml version="1.0" encoding="utf-8"?><error>'+message+'</error>'
  elsif output_format == 'json'
    # A bit of a hack, but switch the code for JSONP requests, since otherwise
    # there's no way for the client Javascript code to know there was an error.
    if callback
      code = 200
    end
    content = make_json({ :error => message }, callback)
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

# Emulates the interface to Yahoo's Placemaker API
# See http://developer.yahoo.com/geo/placemaker/guide/web-service.html for documentation
def placemaker_api_call(params)
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
    fatal_error('Unsupported inputLanguage: "'+input_language+'"', output_type, 500, callback)
  end

  if output_type != 'xml' and output_type != 'json'
    fatal_error('Unsupported outputType: "'+output_type+'"', output_type, 500, callback)
  end

  if !document_content and !document_url
    fatal_error('You must specify either a documentContent or a documentURL parameter', output_type, 500, callback)
  end

  if document_url
    fatal_error('The documentURL method of grabbing content is not yet supported', output_type, 500, callback)
  end

  if document_type != 'text/plain'
    fatal_error('Unsupported documentType: "'+document_type+'"', output_type, 500, callback)
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

  # Convert the raw locations into a form that works well with Yahoo's format
  yahoo_locations = []
  locations.each_with_index do |location_info, index|

    found_tokens = location_info[:found_tokens]

    match_start_index = found_tokens[0][:start_index]
    match_end_index = found_tokens[found_tokens.length-1][:end_index]
    matched_string = input_text[match_start_index..match_end_index]

    location = found_tokens[0]
    yahoo_locations.push({
      # We don't have the actual WOEID, so just create a locally-unique ID
      :woeid => index.to_s,
      :yahoo_type => convert_geodict_to_yahoo_type(location[:type]),
      :name => location[:matched_string],
      :lat => location[:lat].to_s,
      :lon => location[:lon].to_s,
      :start_index => location[:start_index].to_s,
      :end_index => location[:end_index].to_s,
      :matched_string => matched_string
    })
  end
  
  first_location = yahoo_locations[0]

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
        <text><![CDATA[#{location[:matched_string]}]]></text>
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
  
  elsif output_type == 'json'

    output_object = {
      'processingTime' => processing_duration.to_s,
      'version' => 'Geodict build 000000',
      'documentLength' => input_text.length.to_s,
      'document' => {
        'administrativeScope' => {
          'woeId' => first_location[:woeid],
          'type' => first_location[:yahoo_type],
          'name' => first_location[:name],
          'centroid' => {
            'latitude' => first_location[:lat],
            'longitude' => first_location[:lon]
          }
        },
        'geographicScope' => {
          'woeId' => first_location[:woeid],
          'type' => first_location[:yahoo_type],
          'name' => first_location[:name],
          'centroid' => {
            'latitude' => first_location[:lat],
            'longitude' => first_location[:lon]
          }
        },
        'extents' => {
          'center' => {
            'latitude' => first_location[:lat],
            'longitude' => first_location[:lon]
          },
          'southWest' => {
            'latitude' => first_location[:lat],
            'longitude' => first_location[:lon]
          },
          'northEast' => {
            'latitude' => first_location[:lat],
            'longitude' => first_location[:lon]
          }
        },
        'referenceList' => []
      }
    }
    
    doc = output_object['document']
    
    yahoo_locations.each_with_index do |location, index|
      
      doc[index] = { 'placeDetails' => {
        'placeId' => (index+1),
        'place' => {
          'woeId' => location[:woeid],
          'type' => location[:yahoo_type],
          'name' => location[:name],
          'centroid' => {
            'latitude' => location[:lat],
            'longitude' => location[:lon]
          }
        },
        'placeReferenceIds' => index,
        'matchType' => 0,
        'weight' => 1,
        'confidence' => 10
      }}
      
      doc['referenceList'].push({ 'reference' => {
        'woeIds' => location[:woeid],
        'placeReferenceId' => (index+1),
        'placeIds' => index.to_s,
        'start' => location[:start_index],
        'end' => location[:end_index],
        'isPlaintextMarker' => 1,
        'text' => location[:matched_string],
        'type' => 'plaintext',
        'xpath' => ''
      }})
      
    end
      
    result = make_json(output_object, callback)
  
  end

  return result
end

# A more standard interface to the same Placemaker functionality for pulling locations from text
def text2places(text, callback=nil)

  locations = find_locations_in_text(text)

  # Convert the raw locations into a form that makes sense for output
  output_locations = []
  locations.each_with_index do |location_info, index|

    found_tokens = location_info[:found_tokens]

    match_start_index = found_tokens[0][:start_index]
    match_end_index = found_tokens[found_tokens.length-1][:end_index]
    matched_string = text[match_start_index..match_end_index]

    location = found_tokens[0]
    
    if location[:code]
      code = location[:code]
    else
      code = ''
    end
    
    output_locations.push({
      :type => location[:type],
      :name => location[:matched_string],
      :latitude => location[:lat].to_s,
      :longitude => location[:lon].to_s,
      :start_index => location[:start_index].to_s,
      :end_index => location[:end_index].to_s,
      :matched_string => matched_string,
      :code => code
    })
  end

  make_json(output_locations, callback)

end

# Takes an array of IP addresses as input, and looks up their locations using the
# free database from GeoMind
def ip2coordinates(ips, callback=nil)

  geoip = Net::GeoIP.new(DSTKConfig::IP_MAPPING_DATABASE)

  output = {}
  ips.each do |ip|
    begin
      record = geoip[ip]
      info = {
        :country_code => record.country_code,
        :country_code3 => record.country_code3,
        :country_name => record.country_name,
        :region => record.region,
        :locality => record.city,
        :latitude => record.latitude,
        :longitude => record.longitude,
        :dma_code => record.dma_code,
        :area_code => record.area_code
      }
      begin
        info[:postal_code] = record.postal_code
      rescue ArgumentError
        info[:postal_code] = ''
      end
    rescue Net::GeoIP::RecordNotFoundError, ArgumentError
      info = nil
    end
    output[ip] = info
  end
  
  output
end

# Takes a possibly JSON-encoded or comma-separated string, and splits into IPs
def ips_list_from_string(ips_string)

  # Do a bit of trickery to handle both JSON-encoded and comma-separated lists of
  # IP addresses
  ips_string.gsub!(/["\[\] ]/, '') #"

  ips_list = ips_string.split(',')
  
end

# Takes either a JSON-encoded string or single address, and produces a Ruby array
def addresses_list_from_string(addresses_string, callback=nil)

  if addresses_string == ''
    fatal_error('Empty string passed in to street2coordinates', 
      'json', 500, callback)
  end

  # Do a bit of trickery to handle both JSON-encoded and single addresses
  first_character = addresses_string[0].chr
  if first_character == '['
    result = JSON.parse(addresses_string)
  else
    result = [addresses_string]
  end
  
  result
end

# Takes either a JSON-encoded string or single address, and produces a Ruby array
def locations_list_from_string(locations_string, callback=nil)

  if locations_string == ''
    fatal_error('Empty string passed in to coordinates2politics', 
      'json', 500, callback)
  end

  # Do a bit of trickery to handle both JSON-encoded and single addresses
  first_character = locations_string[0].chr
  if first_character == '['
    list = JSON.parse(locations_string)
    result = []
    if (list.length == 2) and (list[0].is_a?(Numeric))
      result.push({ :latitude => list[0].to_f, :longitude => list[1].to_f})
    else
      list.each do |item|
        result.push({ :latitude => item[0].to_f, :longitude => item[1].to_f})
      end
    end
  else
    coordinates = locations_string.split(',')
    if coordinates.length != 2
      fatal_error('Couldn\t understand string "'+locations_string+'" passed into coordinates2politics', 
        'json', 500, callback)
    end
    result = [{ :latitude => coordinates[0].to_f, :longitude => coordinates[1].to_f }] 
  end
  
  result
end

# Converts an HTML string into text
def html2text(html)

  web_doc = Hpricot(html)
  web_doc.search("//comment()").remove
  web_doc.search("script").remove
  web_doc.search("style").remove
  web_doc.search("noscript").remove
  web_doc.search("object").remove
  web_doc.search("embed").remove
  web_doc.search("head").remove

  result = ''
  web_doc.traverse_text do |e| 

    begin
      if e.content
        result += e.content+"\n"
      end
    rescue
      # ignore errors
    end
  end

  if result == ''
    result = strip_tags(html)
  end

  coder = HTMLEntities.new
  result = coder.decode(result)

  result.gsub!(/\n[\n \t]*/, "\n")

  result
end

# Performs OCR on the image to pull out any text
def imagefile2text(filename, content_type)

  image_suffix = content_type.gsub(/^image\//, '')

  suffix_filename = filename+'.'+image_suffix
  `mv #{filename} #{suffix_filename}` 

  exit_code = $?.to_i
  if exit_code != 0
    return nil
  end
  
  output = `ocroscript recognize --output-mode=text #{suffix_filename}`
  exit_code = $?.to_i
  if exit_code != 0
    return nil
  end
    
  output
end

# Pulls the text from a PDF file
def pdffile2text(filename)

  html = `pdftohtml -stdout -noframes #{filename}`
  exit_code = $?.to_i
  if exit_code != 0
    return nil
  end
    
  output = html2text(html)

  output
end

# Converts a Microsoft Word document into plain text
def wordfile2text(filename)

  output = `catdoc #{filename}`

  exit_code = $?.to_i

  if exit_code != 0
    return nil
  end
    
  output
end

# Converts a Microsoft Excel spreadsheet into CSV format
def excelfile2text(filename)

  output = `xls2csv #{filename}`
  exit_code = $?.to_i
  if exit_code != 0
    return nil
  end
    
  output
end

# Unzips the given file to a folder and returns the path
def unzip_to_temp(filename)
    
  output_folder = '/tmp/unzip_'+ActiveSupport::SecureRandom.hex(8)+'/'

  `unzip #{filename} -d #{output_folder}`
  exit_code = $?.to_i
  if exit_code != 0
    fatal_error('Could not unzip to folder '+output_folder)
  end

  return output_folder
end

# Uses a simple regular-expression approach to remove all tags
def strip_tags(input)
  input.gsub(/<[^>]*>/, '')
end

# Converts a new-style Microsoft Word XML document into plain text
def wordxmlfile2text(filename)

  folder_name = unzip_to_temp(filename)

  document = open(folder_name+'word/document.xml').read()

  `rm -rf #{folder_name}`

  output = strip_tags(document)

  output
end

# Converts a new-style Excel XML document into plain text
def excelxmlfile2text(filename)

  folder_name = unzip_to_temp(filename)

  output = ''
  Dir.glob(folder_name+'xl/worksheets/*.xml').each do|f|
    document = open(f).read()
    
    document.gsub!(/<\/c>/, ',')
    document.gsub!(/<\/row>/, "\n")

    output += strip_tags(document)+"\n"
  
  end

  `rm -rf #{folder_name}`

  output
end

# Runs the Boilerpipe framework to strip boilerplate content from HTML
def boilerpipe(input_html)

  begin

    tempfile = Tempfile.new('boilerpipe')
    tempfile << input_html
    tempfile_path = tempfile.path

    bp = DSTKConfig::BOILERPIPE_FOLDER
    output = `java -Dfile.encoding=UTF-8 -cp #{bp}dist/boilerpipe-1.1-dev.jar:#{bp}lib/xerces-2.9.1.jar:#{bp}lib/nekohtml-1.9.13.jar:#{bp}src/ BoilerpipeCLI < #{tempfile_path}`

    exit_code = $?.to_i
    if exit_code != 0
      fatal_error('Error running Boilerpipe')
    end
  rescue
    fatal_error('Exception running Boilerpipe')  
  end

  output
end


########################################
# Methods to directly serve up content #
########################################

# The main page.
get '/' do
  
  @headline = 'Welcome to the Data Science Toolkit'
  
  haml :welcome

end

get '/developerdocs' do
  
  @headline = 'Developer Documentation'
  @statistics = list_available_statistics

  haml :developerdocs

end

get '/about' do
  
  @headline = 'About'
  
  haml :about

end

# Looks like an API method, but isn't. We need this to make file uploading simpler, since there's
# no way to access the contents of a user file on the client side. This is purely a convenience
# function for the front-end though, don't write any external code relying on its existence!
post '/file2method' do

  # Pull out the data we were given
  unless params[:inputfile] &&
    (tmpfile = params[:inputfile][:tempfile]) &&
    (name = params[:inputfile][:filename]) &&
    (content_type = params[:inputfile][:type])
    fatal_error('Something went wrong with the file uploading', 'json', 500)
  end
  
  method = params[:method]
  
  tmpfile_name = tmpfile.path()

  if method == 'street2coordinates'
    file_data = tmpfile.read
    input_array = file_data.split("\n")
    output = street2coordinates(input_array)
    result = [[
      'input', 
      'latitude', 
      'longitude', 
      'country_code', 
      'country_code3', 
      'country_name',
      'region',
      'locality',
      'street_address',
      'street_number',
      'street_name',
      'confidence',
      'fips_county',
    ]]
    if output and output.length > 0
    
      output.each do |input, info|
      
        result.push([
          input,
          info[:latitude],
          info[:longitude],
          info[:country_code],
          info[:country_code3],
          info[:country_name],
          info[:region],
          info[:locality],
          info[:street_address],
          info[:street_number],
          info[:street_name],
          info[:confidence],
          info[:fips_county],
        ])
        
      end

    end

    text = ''
    result.each do |row|
      text << CSV.generate_line(row) + "\n"
    end
      
  elsif method == 'coordinates2politics'

    reader = CSV.open(tmpfile_name, "r")
    header = reader.shift
    
    input_array = []
    latitude_index = nil
    longitude_index = nil
    header.each_with_index do |value, index|
      lower_value = value.downcase
      if lower_value == 'latitude' or lower_value == 'lat'
        latitude_index = index
      end
      if lower_value == 'longitude' or lower_value == 'lon' or lower_value == 'long' or lower_value == 'lng'
        longitude_index = index
      end
    end
    if !latitude_index or !longitude_index
      latitude_index = 0
      longitude_index = 1
      input_array.push({:latitude => header[latitude_index], :longitude => header[longitude_index]})    
    end
    
    reader.each do |row|
      input_array.push({:latitude => row[latitude_index], :longitude => row[longitude_index]})    
    end

    output = coordinates2politics(input_array)
    result = [[
      'latitude', 
      'longitude', 
      'name', 
      'code', 
      'type',
      'friendly_type',
    ]]
    if output and output.length > 0
    
      output.each do |info|
            
        location = info[:location]
        if info[:politics]
          politics_list = info[:politics]
        else
          politics_list = []
        end
      
        politics_list.each do |politics|
        
          result.push([
            location[:latitude],
            location[:longitude],
            politics[:name],
            politics[:code],
            politics[:type],
            politics[:friendly_type],
          ])
        
        end
        
      end      
    end

    text = ''
    result.each do |row|
      text << CSV.generate_line(row) + "\n"
    end

  elsif method == 'ip2coordinates'
    file_data = tmpfile.read
    input_lines = file_data.split("\n")
    ip_array = []
    input_lines.each do |line|

      ip_match = /[12]?\d?\d\.[12]?\d?\d\.[12]?\d?\d\.[12]?\d?\d/.match(line)
      if ip_match
        ip_array.push(ip_match.to_s)
      end
      
    end

    ip_hash = Hash.new(0)
    ip_array.each { |ip| ip_hash[ip] += 1 }

    output = ip2coordinates(ip_hash.keys)
    result = [[
      'input', 
      'value',
      'latitude', 
      'longitude', 
      'country_code', 
      'country_code3', 
      'country_name',
      'region',
      'locality',
      'dma_code',
      'area_code',
    ]]
    if output and output.length > 0
    
      output.each do |input, info|
      
        if !info
          next
        end
      
        result.push([
          input,
          ip_hash[input],
          info[:latitude],
          info[:longitude],
          info[:country_code],
          info[:country_code3],
          info[:country_name],
          info[:region],
          info[:locality],
          info[:dma_code],
          info[:area_code],
          info[:postal_code],
        ])
        
      end

    end

    text = ''
    result.each do |row|
      text << CSV.generate_line(row) + "\n"
    end
  
  else
    fatal_error('Method I don\'t know: "'+method+'"', 'json', 500)  
  end

  if !text
    fatal_error('Error when converting file to text', 'json', 500)
  end

  attachment(name+'.csv')
  content_type('text/csv')

  text


end

########################################
# API entry points                     #
########################################

# Returns version information about this server
get '/info/?' do

  callback = params[:callback]

  content_type 'application/json'
  make_json({:version => DSTKConfig::API_VERSION}, callback)

end

# The normal POST interface for Yahoo's Placemaker
post '/v1/document' do
  placemaker_api_call(params)
end

# Also support a non-standard GET version of the API for Javascript clients
get '/v1/document' do
  placemaker_api_call(params)
end

# The more standard REST/JSON interface for the Placemaker emulation
post '/text2places/?' do

  # Pull in the raw data in the body of the request
  text = request.env['rack.input'].read

  text2places(text)
end

# Also support a non-standard GET version of the API for Javascript clients
get '/text2places/*' do
  callback = params[:callback]
  text = JSON.parse(params['splat'][0])[0]

  text2places(text, callback)
end

# The POST interface for the IP address to location lookup
post '/ip2coordinates/?' do
  # Pull in the raw data in the body of the request
  ips_string = request.env['rack.input'].read
  
  if !ips_string
    fatal_error('You need to place the IP addresses as a comma-separated list inside the POST body', 
      'json', 500, nil)
  end
  # This is a special case. If you pass in an empty string, use the IP address of the requesting
  # client, since javascript callers may not have access to it themselves.
  if ips_string.length == 0
    client_ip_address = @env.has_key?("HTTP_X_FORWARDED_FOR") ? @env["HTTP_X_FORWARDED_FOR"] : @env["REMOTE_ADDR"]
    ips_string = '["' + client_ip_address + '"]'
  end
  ips_list = ips_list_from_string(ips_string)

  output = ip2coordinates(ips_list)
  
  content_type 'application/json'
  make_json(output)
end

# The GET interface for the IP address to location lookup
get '/ip2coordinates/:ips?' do

  callback = params[:callback]
  ips_string = params[:ips]
  if !ips_string or ips_string == '""'
    # This is a special case. If you pass in an empty string, use the IP address of the requesting
    # client, since javascript callers may not have access to it themselves.
    client_ip_address = @env.has_key?("HTTP_X_FORWARDED_FOR") ? @env["HTTP_X_FORWARDED_FOR"] : @env["REMOTE_ADDR"]
    ips_string = '["' + client_ip_address + '"]'
  end
  ips_list = ips_list_from_string(ips_string)

  output = ip2coordinates(ips_list, callback)
  
  content_type 'application/json'
  make_json(output, callback)
end

# The POST interface for the street address to location lookup
post '/street2coordinates/?' do
  begin
    # Pull in the raw data in the body of the request
    addresses_string = request.env['rack.input'].read
    
    if !addresses_string
      fatal_error('You need to place the street addresses as a JSON-encoded array of strings inside the POST body', 
        'json', 500, nil)
    end
    addresses_list = addresses_list_from_string(addresses_string)

    output = street2coordinates(addresses_list)
    content_type 'application/json'
    result = make_json(output)
    result
  rescue
    fatal_error('street2coordinates error: '+$!.inspect + $@.inspect, 'json', 500)
  end

end

# The GET interface for the street address to location lookup
get '/street2coordinates/*' do

  callback = params[:callback]

  begin
    addresses_string = params['splat'][0]
    if !addresses_string
      fatal_error('You need to place the street addresses as a JSON-encoded array of strings as part of the URL', 
        'json', 500, callback)
    end

    addresses_list = addresses_list_from_string(addresses_string, callback)

    output = street2coordinates(addresses_list)
    content_type 'application/json'
    result = make_json(output, callback)
    result
  rescue
    fatal_error('street2coordinates error: '+$!.inspect + $@.inspect, 'json', 500, callback)
  end
    
end

# The POST interface for the location to political areas lookup
post '/coordinates2politics/?' do
  begin
    # Pull in the raw data in the body of the request
    locations_string = request.env['rack.input'].read
    
    if !locations_string
      fatal_error('You need to place the latitude/longitude coordinates as a JSON-encoded array inside the POST body', 
        'json', 500, nil)
    end

    locations_list = locations_list_from_string(locations_string)

    result = coordinates2politics(locations_list)

    content_type 'application/json'
    make_json(result)

  rescue
    fatal_error('coordinates2politics error: '+$!.inspect + $@.inspect, 'json', 500)
  end

end

# The GET interface for the location to political areas lookup
get '/coordinates2politics/*' do

  callback = params[:callback]

#  begin
    locations_string = params['splat'][0]
    if !locations_string
      fatal_error('You need to place the latitude/longitude coordinates as a JSON-encoded array as part of the URL', 
        'json', 500, callback)
    end
    
    locations_list = locations_list_from_string(locations_string, callback)

    result = coordinates2politics(locations_list, callback)

    make_json(result, callback)

#  rescue
#    fatal_error('coordinates2politics error: '+$!.inspect + $@.inspect, 'json', 500, callback)
#  end

end

# The interface used to convert a pdf/word/excel/image file into text
post '/file2text/?' do

  # Pull out the data we were given
  unless params[:inputfile] &&
    (tmpfile = params[:inputfile][:tempfile]) &&
    (name = params[:inputfile][:filename]) &&
    (content_type = params[:inputfile][:type])
    fatal_error('Something went wrong with the file uploading', 'json', 500)
  end
  
  tmpfile_name = tmpfile.path()

  # We weren't given a proper content type, so try to guess
  if content_type == 'application/octet-stream'

    extension = File.extname(name)
    extension.gsub!(/\./, '').downcase!()
    
    known_extensions = {
      'txt' => 'text/plain',
      'htm' => 'text/html',
      'html' => 'text/html',
      'png' => 'image/png',
      'jpg' => 'image/jpeg',
      'jpeg' => 'image/jpeg',
      'tif' => 'image/tiff',
      'tiff' => 'image/tiff',
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    }

    if known_extensions.has_key?(extension)
      content_type = known_extensions[extension]
    end
  end

  if content_type == 'text/plain'
    file_data = tmpfile.read
    text = file_data
  elsif content_type == 'text/html'
    file_data = tmpfile.read
    text = html2text(file_data)
  elsif content_type =~ /image\/*/
    text = imagefile2text(tmpfile_name, content_type)
  elsif content_type == 'application/pdf'
    text = pdffile2text(tmpfile_name)
  elsif content_type == 'application/msword'
    text = wordfile2text(tmpfile_name)
  elsif content_type == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    text = wordxmlfile2text(tmpfile_name)
  elsif content_type == 'application/vnd.ms-excel'
    text = excelfile2text(tmpfile_name)
  elsif content_type == 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    text = excelxmlfile2text(tmpfile_name)
  else
    fatal_error('Mime type I don\'t know how to convert: "'+content_type+'"', 'json', 500)  
  end

  if !text
    fatal_error('Error when converting file to text', 'json', 500)
  end

  attachment(name+'.txt')
  content_type('text/plain')

  text
end

# Returns the portions of the text that look like sentences
post '/text2sentences/?' do

  # Pull in the raw data in the body of the request
  text = request.env['rack.input'].read

  output_text = strip_nonsentences(text)
  
  content_type 'application/json'
  make_json({:sentences => output_text})
end

get '/text2sentences/*' do
  callback = params[:callback]
  text = JSON.parse(params['splat'][0])[0]

  output_text = strip_nonsentences(text)
  
  content_type 'application/json'
  make_json({:sentences => output_text}, callback)
end

# Extracts the displayed text from the input HTML
post '/html2text/?' do

  # Pull in the raw data in the body of the request
  text = request.env['rack.input'].read

  output_text = html2text(text)
  
  content_type 'application/json'
  make_json({:text => output_text})
end

get '/html2text/*' do
  callback = params[:callback]
  text = JSON.parse(params['splat'][0])[0]

  output_text = html2text(text)
  
  content_type 'application/json'
  make_json({:text => output_text}, callback)
end

# Extracts the main story text from the input HTML
post '/html2story/?' do

  # Pull in the raw data in the body of the request
  text = request.env['rack.input'].read

  output_text = boilerpipe(text)
  
  content_type 'application/json'
  make_json({:story => output_text})
end

get '/html2story/*' do
  callback = params[:callback]
  text = JSON.parse(params['splat'][0])[0]

  output_text = boilerpipe(text)
  
  content_type 'application/json'
  make_json({:story => output_text}, callback)
end

# Pulls out strings that look like people's names
post '/text2people/?' do

  # Pull in the raw data in the body of the request
  text = request.env['rack.input'].read

  results = text2people(text)

  content_type 'application/json'
  make_json(results)
end

get '/text2people/*' do
  callback = params[:callback]
  text = JSON.parse(params['splat'][0])[0]

  results = text2people(text)

  content_type 'application/json'
  make_json(results, callback)
end

# Pulls out strings that look like times or dates
post '/text2times/?' do

  # Pull in the raw data in the body of the request
  text = request.env['rack.input'].read

  results = text2times(text)

  content_type 'application/json'
  make_json(results)
end

get '/text2times/*' do
  callback = params[:callback]
  text = JSON.parse(params['splat'][0])[0]

  results = text2times(text)

  content_type 'application/json'
  make_json(results, callback)
end

# Returns a sentiment score for the input text
post '/text2sentiment/?' do

  # Pull in the raw data in the body of the request
  text = request.env['rack.input'].read

  score = text2sentiment(text)
  result = {'score' => score}

  content_type 'application/json'
  make_json(result)
end

get '/text2sentiment/*' do
  callback = params[:callback]
  text = params['splat'][0]
  text.gsub!(/^\["(.*)"\]$/, '\1')

  score = text2sentiment(text)
  result = {'score' => score}

  content_type 'application/json'
  make_json(result, callback)
end

get '/maps/api/geocode/:format' do
  callback = params[:callback]
  result = google_geocoder_api_call(params)
  content_type 'application/json'
  make_json(result, callback)
end

# The POST interface for the location to statistics endpoint
post '/coordinates2statistics' do
  begin
    # Pull in the raw data in the body of the request
    locations_string = request.env['rack.input'].read
    
    if !locations_string
      fatal_error('You need to place the latitude/longitude coordinates as a JSON-encoded array inside the POST body', 
        'json', 500, nil)
    end

    wanted = nil
    if params[:statistics]
      wanted = params[:statistics].split(',')
    end

    locations_list = locations_list_from_string(locations_string)

    result = []
    locations_list.each do |location|
      statistics = coordinates2statistics(location[:latitude], location[:longitude], wanted)
      result << {
        'location' => location,
        'statistics' => statistics,
      }
    end

    content_type 'application/json'
    make_json(result)

  rescue
    fatal_error('coordinates2statistics error: '+$!.inspect + $@.inspect, 'json', 500)
  end

end

# The GET interface for the location to statistics endpoint
get '/coordinates2statistics/*' do

  callback = params[:callback]

  begin
    locations_string = params['splat'][0]
    if !locations_string
      fatal_error('You need to place the latitude/longitude coordinates as a JSON-encoded array as part of the URL', 
        'json', 500, callback)
    end

    wanted = nil
    if params[:statistics]
      wanted = params[:statistics].split(',')
    end

    locations_list = locations_list_from_string(locations_string, callback)

    result = []
    locations_list.each do |location|
      statistics = coordinates2statistics(location[:latitude], location[:longitude], wanted)
      result << {
        'location' => location,
        'statistics' => statistics,
      }
    end

    content_type 'application/json'
    make_json(result, callback)

  rescue
    fatal_error('coordinates2statistics error: '+$!.inspect + $@.inspect, 'json', 500, callback)
  end

end

