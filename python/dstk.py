# Python interface to the Data Science Toolkit Plugin
# version: 1.30 (2011-03-16)
#
# See http://www.geodictapi.com/developerdocs for more details
#
# All code (C) Pete Warden, 2011
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import urllib
try:
  import simplejson as json
except ImportError:
  import json
import os

# This is the main interface class. You can see an example of it in use
# below, implementing a command-line tool, but you basically just instantiate
# dstk = DSTK()
# and then call the method you want
# coordinates = dstk.ip2coordinates('12.34.56.78')
# The full documentation is at http://www.geodictapi.com/developerdocs
class DSTK:

  api_base = None

  def __init__(self, options=None):
    if options is None:
      options = {}
    
    defaultOptions = {
      'apiBase': 'http://www.geodictapi.com',
      'checkVersion': True
    }

    if 'DSTK_API_BASE' in os.environ:
      defaultOptions['apiBase'] = os.environ['DSTK_API_BASE']
    
    for key, value in defaultOptions.items():
      if key not in options:
        options[key] = value
        
    self.api_base = options['apiBase']

    if options['checkVersion']:
      self.check_version()
      
  def check_version(self):
  
    required_version = 130
    
    api_url = self.api_base+'/info'
    
    try:    
      response_string = urllib.urlopen(api_url).read()
      response = json.loads(response_string)
    except:
      raise Exception('The server at "'+self.api_base+'" doesn\'t seem to be running DSTK, no version information found.')

    actual_version = response['version']
    if actual_version < required_version:
      raise Exception('DSTK: Version '+str(actual_version)+' found at "'+api_url+'" but '+str(required_version)+' is required')

  def ip2coordinates(self, ips):
    
    if not isinstance(ips, (list, tuple)):
      ips = [ips]
  
    api_url = self.api_base+'/ip2coordinates'
    api_body = json.dumps(ips)
    response_string = urllib.urlopen(api_url, api_body).read()
    
    response = json.loads(response_string)
    
    if 'error' in response:
      raise Exception(response['error'])
    
    return response

  def street2coordinates(self, addresses):
    
    if not isinstance(addresses, (list, tuple)):
      addresses = [addresses]
  
    api_url = self.api_base+'/street2coordinates'
    api_body = json.dumps(addresses)
    response_string = urllib.urlopen(api_url, api_body).read()
    response = json.loads(response_string)
    
    if 'error' in response:
      raise Exception(response['error'])
    
    return response
    
  def coordinates2politics(self, coordinates):
    
    if not isinstance(coordinates, (list, tuple)):
      coordinates = [coordinates]
  
    api_url = self.api_base+'/coordinates2politics'
    api_body = json.dumps(coordinates)
    print api_body
    response_string = urllib.urlopen(api_url, api_body).read()
    response = json.loads(response_string)
    
    if 'error' in response:
      raise Exception(response['error'])
    
    return response

  def text2places(self, text):
    
    api_url = self.api_base+'/text2places'
    api_body = text
    response_string = urllib.urlopen(api_url, api_body).read()
    response = json.loads(response_string)
    
    if 'error' in response:
      raise Exception(response['error'])
    
    return response

# End of the interface. The rest of this file is an example implementation of a
# command line client.

def ip2coordinates_cli(dstk, options, inputs):

  result = dstk.ip2coordinates(inputs)
  
  output = ''

  if options['showHeaders']:
    for ip, info in result.items():
      if info is None:
        continue
      row = ['ip_address']
      for key, value in info.items():
        row.append(str(key))
      output += ','.join(row)+"\n"
      break
      
  for ip, info in result.items():

    if info is None:
      info = {}

    row = [ip]
    for key, value in info.items():
      row.append(str(value))

    row_string = '","'.join(row)
      
    output += '"'+row_string+'"'+"\n"
    
  return output
    
def street2coordinates_cli(dstk, options, inputs):

  result = dstk.street2coordinates(inputs)
  
  output = ''

  if options['showHeaders']:
    for ip, info in result.items():
      if info is None:
        continue
      row = ['address']
      for key, value in info.items():
        row.append(str(key))
      output += ','.join(row)+"\n"
      break

  for ip, info in result.items():

    if info is None:
      info = {}

    row = [ip]
    for key, value in info.items():
      row.append(str(value))

    row_string = '","'.join(row)
      
    output += '"'+row_string+'"'+"\n"
    
  return output

def coordinates2politics_cli(dstk, options, inputs):

  coordinates_list = []
  for input in inputs:
    coordinates = input.split(',')
    if len(coordinates)!=2:
      print 'You must enter coordinates as a series of comma-separated pairs, eg 37.76,-122.42'
      exit(-1)
    coordinates_list.append({
      'latitude': coordinates[0],
      'longitude': coordinates[1],
    })

  result = dstk.coordinates2politics(coordinates_list)
  
  output = ''

  if options['showHeaders']:
    row = ['latitude', 'longitude', 'name', 'code', 'type', 'friendly_type']
    output += ','.join(row)+"\n"
      
  for info in result:

    location = info['location']
    politics = info['politics']

    for politic in politics:
      row = [location['latitude'], 
        location['longitude'], 
        politic['name'],
        politic['code'],
        politic['type'],
        politic['friendly_type'],
      ]
      row_string = '","'.join(row)      
      output += '"'+row_string+'"'+"\n"
    
  return output

def print_usage(message=''):

  print message
  print "Usage:"
  print "python dstk.py <command> [-a/--api_base 'http://yourhost.com'] [-h/--show_headers] <inputs>"
  print "Where <command> is one of:"
  print "  ip2coordinates" 
  print "  street2coordinates" 
  print "  coordinates2politics" 
  print "  text2places"
  print "If no inputs are specified, then standard input will be read and used"
  print "See http://www.geodictapi.com/developerdocs for more details"
  print "Example:"
  print "python dstk.py ip2coordinates 67.169.73.113" 

  exit(-1)

def text2places_cli(dstk, options, inputs):

  text = "\n".join(inputs)

  result = dstk.text2places(text)
  
  output = ''
  if options['showHeaders']:
    row = ['latitude', 'longitude', 'name', 'type', 'start_index', 'end_index', 'matched_string']
    output += ','.join(row)+"\n"
      
  for info in result:

    row = [info['latitude'], 
      info['longitude'], 
      info['name'],
      info['type'],
      info['start_index'],
      info['end_index'],
      info['matched_string'],
    ]
    row_string = '","'.join(row)      
    output += '"'+row_string+'"'+"\n"
    
  return output

if __name__ == '__main__': 

  import sys

  commands = {
    'ip2coordinates': { 'handler': ip2coordinates_cli },
    'street2coordinates': { 'handler': street2coordinates_cli },
    'coordinates2politics': { 'handler': coordinates2politics_cli },
    'text2places': { 'handler': text2places_cli },
  }
  switches = {
    'api_base': True,
    'show_headers': True
  }
  
  command = None
  options = {'showHeaders': False}
  inputs = []
  
  ignore_next = False
  for index, arg in enumerate(sys.argv[1:]):
    if ignore_next:
      ignore_next = False
      continue
    
    if arg[0]=='-' and len(arg)>1:
      if len(arg) == 2:
        letter = arg[1]
        if letter == 'a':
          option = 'api_base'
        elif letter == 'h':
          option = 'show_headers'
      else:
        option = arg[2:]

      if option not in switches:
        print_usage('Unknown option "'+arg+'"')
      
      if option == 'api_base':
        if (index+2) >= len(sys.argv):
          print_usage('Missing argument for option "'+arg+'"')
        options['apiBase'] = sys.argv[index+2]
        ignore_next = True
      elif option == 'show_headers':
        options['showHeaders'] = True
    
    else:
      if command is None:
        command = arg
        if command not in commands:
          print_usage('Unknown command "'+arg+'"')
      else:
        inputs.append(arg)

  if command is None:
    print_usage('No command specified')
        
  if len(inputs)<1:
    inputs = sys.stdin.readlines()
    
  command_info = commands[command]
  
  dstk = DSTK(options)
  
  result = command_info['handler'](dstk, options, inputs)
  
  print result