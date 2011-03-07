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

require 'rubygems'
require 'daemons'

pwd = Dir.pwd
Daemons.run_proc('geodict_server.rb', {
  :dir_mode => :normal, 
  :dir => '/opt/pids/sinatra', 
  :log_output => true
  }) do
  Dir.chdir(pwd)
  exec 'ruby geodict_server.rb'
end