#!/usr/bin/ruby
#

###################################################################################
# GEMS
require 'securerandom'

###################################################################################
# CUSTOM
require_relative 'path'

###################################################################################
# PUSH
#
# This ruby script takes as arguments a mapper python script and a reducer python
# script and creates a copy of them in a separate folder, ready to be used for
# later execution.
#
# If no mapper and reducer is provided, assumes default values of:
# Mapper:  src/mapper.py
# Reducer: src/reducer.py
###################################################################################

M = ARGV.fetch 0, 'mapper.py'
R = ARGV.fetch 1, 'reducer.py'

U = Path.queue SecureRandom.uuid

MS = Path.source M
MT = File.join(U, M)

RS = Path.source R
RT = File.join(U, R)

abort 'Mapper does not exist.'  if not File.exist? MS
abort 'Reducer does not exist.' if not File.exist? RS

%x[mkdir -p #{U}]
%x[cp #{MS} #{MT}]
%x[cp #{RS} #{RT}]

puts "Created new MR instance:[ #{U} ]"