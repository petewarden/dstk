# Data Science Toolkit
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

module DSTKConfig

  # The location of the source data to be loaded into your database
  SOURCE_FOLDER = '../dstkdata/'

  # Your MySQL user credentials
  USER = 'postgres'
  PASSWORD = ''

  # The address and port number of your database server
  HOST = 'localhost'
  PORT = 5432

  # The name of the database holding the gazetteer data
  DATABASE = 'geodict'

  # The name of the database holding the geometry used in reverse geocoding
  REVERSE_GEO_DATABASE = 'reversegeo'

  # The maximum number of words in any name
  WORD_MAX = 3

  # Words that provide evidence that what follows them is a location
  LOCATION_WORDS = {
      'at' => true,
      'in' => true
  }

  # The location of the MaxMind database file holding IP to location mappings
  IP_MAPPING_DATABASE = '../dstkdata/GeoLiteCity.dat'
  
  # The version of the API this code implements
  API_VERSION = 30
  
  # The home of the Boilerplate framework
  BOILERPIPE_FOLDER = '../boilerpipe/boilerpipe-core/'

end