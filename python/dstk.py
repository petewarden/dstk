#!/usr/bin/env python
# Python interface to the Data Science Toolkit Plugin
# version: 1.30 (2011-03-16)
#
# See http://www.datasciencetoolkit.org/developerdocs#python for full details
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
import httplib
import mimetypes
import re
import csv


# This is the main interface class. You can see an example of it in use
# below, implementing a command-line tool, but you basically just instantiate
# dstk = DSTK()
# and then call the method you want
# coordinates = dstk.ip2coordinates('12.34.56.78')
# The full documentation is at http://www.datasciencetoolkit.org/developerdocs
class DSTK:

  api_base = None

  def __init__(self, options=None):
    if options is None:
      options = {}
    
    defaultOptions = {
      'apiBase': 'http://www.datasciencetoolkit.org',
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
  
    required_version = 35
    
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
    
    api_url = self.api_base+'/coordinates2politics'
    api_body = json.dumps(coordinates)
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

  def file2text(self, file_name, file_data):

    host = self.api_base.replace('http://', '')

    response = post_multipart(host,
      '/file2text',[],[('inputfile', file_name, file_data)])
  
    return response

  def text2sentences(self, text):
    
    api_url = self.api_base+'/text2sentences'
    api_body = text
    response_string = urllib.urlopen(api_url, api_body).read()
    response = json.loads(response_string)
    
    if 'error' in response:
      raise Exception(response['error'])
    
    return response

  def html2text(self, html):
    
    api_url = self.api_base+'/html2text'
    api_body = html
    response_string = urllib.urlopen(api_url, api_body).read()
    response = json.loads(response_string)
    
    if 'error' in response:
      raise Exception(response['error'])
    
    return response

  def html2story(self, html):
    
    api_url = self.api_base+'/html2story'
    api_body = html
    response_string = urllib.urlopen(api_url, api_body).read()
    response = json.loads(response_string)
    
    if 'error' in response:
      raise Exception(response['error'])
    
    return response

  def text2people(self, text):
    
    api_url = self.api_base+'/text2people'
    api_body = text
    response_string = urllib.urlopen(api_url, api_body).read()
    response = json.loads(response_string)
    
    if 'error' in response:
      raise Exception(response['error'])
    
    return response

  def text2times(self, text):
    
    api_url = self.api_base+'/text2times'
    api_body = text
    response_string = urllib.urlopen(api_url, api_body).read()
    response = json.loads(response_string)
    
    if 'error' in response:
      raise Exception(response['error'])
    
    return response

# We need to post files as multipart form data, and Python has no native function for
# that, so these utility functions implement what we need.
# See http://code.activestate.com/recipes/146306/ 
def post_multipart(host, selector, fields, files):
    """
    Post fields and files to an http host as multipart/form-data.
    fields is a sequence of (name, value) elements for regular form fields.
    files is a sequence of (name, filename, value) elements for data to be uploaded as files
    Return the server's response page.
    """
    content_type, body = encode_multipart_formdata(fields, files)
    h = httplib.HTTP(host)
    h.putrequest('POST', selector)
    h.putheader('content-type', content_type)
    h.putheader('content-length', str(len(body)))
    h.endheaders()
    h.send(body)
    errcode, errmsg, headers = h.getreply()
    return h.file.read()

def encode_multipart_formdata(fields, files):
    """
    fields is a sequence of (name, value) elements for regular form fields.
    files is a sequence of (name, filename, value) elements for data to be uploaded as files
    Return (content_type, body) ready for httplib.HTTP instance
    """
    BOUNDARY = '----------ThIs_Is_tHe_bouNdaRY_$'
    CRLF = '\r\n'
    L = []
    for (key, value) in fields:
        L.append('--' + BOUNDARY)
        L.append('Content-Disposition: form-data; name="%s"' % key)
        L.append('')
        L.append(value)
    for (key, filename, value) in files:
        L.append('--' + BOUNDARY)
        L.append('Content-Disposition: form-data; name="%s"; filename="%s"' % (key, filename))
        L.append('Content-Type: %s' % guess_content_type(filename))
        L.append('')
        L.append(value)
    L.append('--' + BOUNDARY + '--')
    L.append('')
    body = CRLF.join(L)
    content_type = 'multipart/form-data; boundary=%s' % BOUNDARY
    return content_type, body

def guess_content_type(filename):
    return mimetypes.guess_type(filename)[0] or 'application/octet-stream'

# End of the interface. The rest of this file is an example implementation of a
# command line client.

def ip2coordinates_cli(dstk, options, inputs, output):

  writer = csv.writer(sys.stdout)
  
  input_ips = []
  for input_line in inputs:
    ip_match = re.match(r'[12]?\d?\d\.[12]?\d?\d\.[12]?\d?\d\.[12]?\d?\d', input_line)
    if ip_match is not None:
      input_ips.append(ip_match.group(0))
    else:
      print 'No match'

  result = dstk.ip2coordinates(input_ips)
  
  if options['showHeaders']:
    for ip, info in result.items():
      if info is None:
        continue
      row = ['ip_address']
      for key, value in info.items():
        row.append(str(key))
      writer.writerow(row)
      break
      
  for ip, info in result.items():

    if info is None:
      info = {}

    row = [ip]
    for key, value in info.items():
      row.append(str(value))

    writer.writerow(row)
    
  return
    
def street2coordinates_cli(dstk, options, inputs, output):

  writer = csv.writer(sys.stdout)

  result = dstk.street2coordinates(inputs)
  
  if options['showHeaders']:
    for ip, info in result.items():
      if info is None:
        continue
      row = ['address']
      for key, value in info.items():
        row.append(str(key))
      writer.writerow(row)
      break

  for ip, info in result.items():

    if info is None:
      info = {}

    row = [ip]
    for key, value in info.items():
      row.append(str(value))

    writer.writerow(row)
    
  return

def coordinates2politics_cli(dstk, options, inputs, output):

  writer = csv.writer(output)

  coordinates_list = []
  for input in inputs:
    coordinates = input.split(',')
    if len(coordinates)!=2:
      output.write('You must enter coordinates as a series of comma-separated pairs, eg 37.76,-122.42')
      exit(-1)
    coordinates_list.append([coordinates[0], coordinates[1]])

  result = dstk.coordinates2politics(coordinates_list)
  
  if options['showHeaders']:
    row = ['latitude', 'longitude', 'name', 'code', 'type', 'friendly_type']
    writer.writerow(row)
      
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
      writer.writerow(row)
    
  return

def file2text_cli(dstk, options, inputs, output):
  
  for file_name in inputs:
    if os.path.isdir(file_name):
      children = os.listdir(file_name)
      full_children = []
      for child in children:
        full_children.append(os.path.join(file_name, child))
      file2text_cli(dstk, options, full_children)
    else:
      file_data = get_file_or_url_contents(file_name)
      if options['showHeaders']:
        output.write('--File--: '+file_name+"\n")
      result = dstk.file2text(file_name, file_data)
      
      print result
  return

def text2places_cli(dstk, options, inputs, output):

  writer = csv.writer(output)
  
  if options['showHeaders']:
    row = ['latitude', 'longitude', 'name', 'type', 'start_index', 'end_index', 'matched_string', 'file_name']
    writer.writerow(row)
  options['showHeaders'] = False

  if options['from_stdin']:
    result = dstk.text2places("\n".join(inputs))
    text2places_format(result, 'stdin', writer)
    return

  for file_name in inputs:
    if os.path.isdir(file_name):
      children = os.listdir(file_name)
      full_children = []
      for child in children:
        full_children.append(os.path.join(file_name, child))
      text2places_cli(dstk, options, full_children, output)
    else:
      file_data = get_file_or_url_contents(file_name)
      result = dstk.text2places(file_data)
      text2places_format(result, file_name, writer)

  return

def text2places_format(result, file_name, writer):
  for info in result:

    row = [info['latitude'], 
      info['longitude'], 
      info['name'],
      info['type'],
      info['start_index'],
      info['end_index'],
      info['matched_string'],
      file_name
    ]
    writer.writerow(row)
  return

def html2text_cli(dstk, options, inputs, output):

  if options['from_stdin']:
    result = dstk.html2text("\n".join(inputs))
    print result['text']
    return

  for file_name in inputs:
    if os.path.isdir(file_name):
      children = os.listdir(file_name)
      full_children = []
      for child in children:
        full_children.append(os.path.join(file_name, child))
      html2text_cli(dstk, options, full_children, output)
    else:
      file_data = get_file_or_url_contents(file_name)
      if options['showHeaders']:
        output.write('--File--: '+file_name+"\n")
      result = dstk.html2text(file_data)
      print result['text']
  return

def text2sentences_cli(dstk, options, inputs, output):

  if options['from_stdin']:
    result = dstk.text2sentences("\n".join(inputs))
    print result['sentences']
    return

  for file_name in inputs:
    if os.path.isdir(file_name):
      children = os.listdir(file_name)
      full_children = []
      for child in children:
        full_children.append(os.path.join(file_name, child))
      text2sentences_cli(dstk, options, full_children, output)
    else:
      file_data = get_file_or_url_contents(file_name)
      if options['showHeaders']:
        output.write('--File--: '+file_name+"\n")
      result = dstk.text2sentences(file_data)
      print result['sentences']

  return

def html2story_cli(dstk, options, inputs, output):

  if options['from_stdin']:
    result = dstk.html2story("\n".join(inputs))
    print result['story']
    return

  for file_name in inputs:
    if os.path.isdir(file_name):
      children = os.listdir(file_name)
      full_children = []
      for child in children:
        full_children.append(os.path.join(file_name, child))
      html2story_cli(dstk, options, full_children, output)
    else:
      file_data = get_file_or_url_contents(file_name)
      if options['showHeaders']:
        output.write('--File--: '+file_name+"\n")
      result = dstk.html2story(file_data)
      print result['story']
  
  return

def text2people_cli(dstk, options, inputs, output):

  writer = csv.writer(sys.stdout)

  if options['showHeaders']:
    row = ['matched_string', 'first_name', 'surnames', 'title', 'gender', 'start_index', 'end_index', 'file_name']
    writer.writerow(row)
  options['showHeaders'] = False

  if options['from_stdin']:
    result = dstk.text2people("\n".join(inputs))
    text2people_format(result, 'stdin', writer)
    return

  for file_name in inputs:
    if os.path.isdir(file_name):
      children = os.listdir(file_name)
      full_children = []
      for child in children:
        full_children.append(os.path.join(file_name, child))
      text2places_cli(dstk, options, full_children, output)
    else:
      file_data = get_file_or_url_contents(file_name)
      result = dstk.text2people(file_data)
      text2people_format(result, file_name, writer)

  return

def text2people_format(result, file_name, writer):
  for info in result:

    row = [
      info['matched_string'],
      info['first_name'], 
      info['surnames'], 
      info['title'],
      info['gender'],
      str(info['start_index']),
      str(info['end_index']),
      file_name
    ]
    writer.writerow(row)
  return

def text2times_cli(dstk, options, inputs, output):

  writer = csv.writer(sys.stdout)

  if options['showHeaders']:
    row = ['matched_string', 'time_string', 'time_seconds', 'is_relative', 'start_index', 'end_index', 'file_name']
    writer.writerow(row)
  options['showHeaders'] = False

  if options['from_stdin']:
    result = dstk.text2times("\n".join(inputs))
    text2times_format(result, 'stdin', writer)
    return

  for file_name in inputs:
    if os.path.isdir(file_name):
      children = os.listdir(file_name)
      full_children = []
      for child in children:
        full_children.append(os.path.join(file_name, child))
      text2times_cli(dstk, options, full_children, output)
    else:
      file_data = get_file_or_url_contents(file_name)
      result = dstk.text2times(file_data)
      text2times_format(result, file_name, writer)

  return

def text2times_format(result, file_name, writer):
  for info in result:

    row = [
      info['matched_string'],
      info['time_string'], 
      info['time_seconds'], 
      info['is_relative'],
      str(info['start_index']),
      str(info['end_index']),
      file_name
    ]
    writer.writerow(row)
  return

def get_file_or_url_contents(file_name):
  if re.match(r'http://', file_name):
    file_data = urllib.urlopen(file_name).read()
  else:
    file_data = open(file_name).read()
  return file_data

def print_usage(message=''):

  print message
  print "Usage:"
  print "python dstk.py <command> [-a/--api_base 'http://yourhost.com'] [-h/--show_headers] <inputs>"
  print "Where <command> is one of:"
  print "  ip2coordinates        (lat/lons for IP addresses)" 
  print "  street2coordinates    (lat/lons for postal addresses)" 
  print "  coordinates2politics  (country/state/county/constituency/etc for lat/lon)" 
  print "  text2places           (lat/lons for places mentioned in unstructured text)"
  print "  file2text             (PDF/Excel/Word to text, and OCR on PNG/Jpeg/Tiff images)"
  print "  text2sentences        (parts of the text that look like proper sentences)"
  print "  html2text             (text version of the HTML document)"
  print "  html2story            (text version of the HTML with no boilerplate)"  
  print "  text2people           (gender for people mentioned in unstructured text)"
  print "  text2times            (times and dates mentioned in unstructured text)"
  print "If no inputs are specified, then standard input will be read and used"
  print "See http://www.datasciencetoolkit.org/developerdocs for more details"
  print "Examples:"
  print "python dstk.py ip2coordinates 67.169.73.113" 
  print "python dstk.py street2coordinates \"2543 Graystone Place, Simi Valley, CA 93065\"" 
  print "python dstk.py file2text scanned.jpg" 

  exit(-1)

if __name__ == '__main__': 

  import sys

  commands = {
    'ip2coordinates': { 'handler': ip2coordinates_cli },
    'street2coordinates': { 'handler': street2coordinates_cli },
    'coordinates2politics': { 'handler': coordinates2politics_cli },
    'text2places': { 'handler': text2places_cli },
    'file2text': { 'handler': file2text_cli },
    'text2sentences': { 'handler': text2sentences_cli },
    'html2text': { 'handler': html2text_cli },
    'html2story': { 'handler': html2story_cli },
    'text2people': { 'handler': text2people_cli },
    'text2times': { 'handler': text2times_cli },
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
    options['from_stdin'] = True
    inputs = sys.stdin.readlines()
  else:
    options['from_stdin'] = False    
  
  command_info = commands[command]
  
  dstk = DSTK(options)
  
  command_info['handler'](dstk, options, inputs, sys.stdout)
