#!/usr/bin/env ruby

require 'rubygems'
require 'daemons'

Daemons.run('/home/ubuntu/sources/dstk/geodict_server.rb', {
  :dir => '/opt/pids/sinatra/',
  :dir_mode => :normal,
  :log_output => true,
})

