#!/usr/bin/env ruby

# Geodict
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

require 'geodict_lib'

require 'rubygems'
require 'choice'
require 'json'

Choice.options do

  option :input, :required => false do
    short '-i'
    long '--input=INPUT'
    desc 'The name of the input file to scan for locations. If none is set, will read from STDIN'
    default '-'
  end

  option :output, :required => false do
    short '-o'
    long '--output=OUTPUT'
    desc 'The name of the file to write the location data to. If none is set, will write to STDOUT'
    default '-'
  end

  option :format, :required => false do
    short '-f'
    long '--format=FORMAT'
    desc 'The format to use to output information about any locations found. By default it will write out location names separated by newlines, but specifying "json" will give more detailed information'
    default 'text'
  end
end


input = Choice.choices[:input]
output = Choice.choices[:output]
format = Choice.choices[:format]

if input == '-'
  input_handle = $stdin
else
  begin
    input_handle = File.open(input, 'rb')
  rescue
    die("Couldn't open file '"+input+"'")
  end
end
        
if output == '-'
  output_handle = $stdout
else
  begin
    output_handle = File.open(output, 'wb')
  rescue
    die("Couldn't write to file '"+output+"'")
  end
end
        
text = input_handle.read()

locations = find_locations_in_text(text)

output_string = ''
if format.downcase == 'json'
  output_string = locations.to_json
  output_handle.write(output_string)
elsif format.downcase == 'text'
  locations.each do |location|
    found_tokens = location[:found_tokens]
    start_index = found_tokens[0][:start_index]
    end_index = found_tokens[found_tokens.length-1][:end_index]
    output_string += text[start_index..end_index]
    output_string += "\n"
  end
  output_handle.write(output_string)
else
  print "Unknown output format '"+format+"'"
  exit()
end
