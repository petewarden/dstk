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

module GeodictConfig

  # The location of the source data to be loaded into your database
  SOURCE_FOLDER = '../geodictdata/'

  # Your MySQL user credentials
  USER = 'postgres'
  PASSWORD = nil

  # The address and port number of your database server
  HOST = 'localhost'
  PORT = 5432

  # The name of the database to create
  DATABASE = 'geodict'

  # The maximum number of words in any name
  WORD_MAX = 3

  # Words that provide evidence that what follows them is a location
  LOCATION_WORDS = {
      'at' => true,
      'in' => true
  }

end