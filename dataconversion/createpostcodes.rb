#!/usr/bin/env ruby

require 'rubygems'

require 'json'
require 'tmpdir'

require File.join(File.expand_path(File.dirname(__FILE__)), '../dstk_config')

SIMPLEGEO_COMMAND = File.join(DSTKConfig::DSTK_ROOT, 'dataconversion/simplegeo2postcodes.rb')
DATA_FOLDER = File.join(DSTKConfig::DSTK_ROOT, '../dstkdata/places_dump_20110628')
DATA_FILE_GLOB = 'places_dump_*.geojson.gz'
OUTPUT_FILE = File.join(Dir.tmpdir, 'postcodes.tsv')

# Empty out the postcode results file to start
`echo > #{OUTPUT_FILE}`

command = 'find ' + DATA_FOLDER + ' -iname "' + DATA_FILE_GLOB + '"'
command += ' -exec bash -x -c'
command += ' "gunzip -c {} | ' + SIMPLEGEO_COMMAND
command +=' | sort >> ' + OUTPUT_FILE + '" \;'

$stderr.puts "Running #{command}"

`#{command}`
