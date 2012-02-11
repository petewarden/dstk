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
def coordinates2demographics(locations, callback=nil)

  politics = coordinates2politics(locations)

  conn = PGconn.connect(DSTKConfig::HOST, DSTKConfig::PORT, '', '', DSTKConfig::REVERSE_GEO_DATABASE, DSTKConfig::USER, DSTKConfig::PASSWORD)

  result = []
  politics.each do |politic|
    
    result.push({
      :location => location,
      :politics => output
    })
  
  end

  result
  
end

#text = open('../cruftstripper/test_data/inputs/cnn.com.html').read()
#output = text2people(text)
#puts output.inspect