#!/usr/bin/ruby

require 'set'
require_relative 'path'

####################################################################################################
# This script parses the output of a reducer file and compares it to the training duplicates file
# that has been provided with the exercise.
#
# It then reports the IDs of all false positives and all false negatives.
####################################################################################################

REDUCED    = ARGV.fetch 0, File.join(Path::PATH_LAST, 'reduced.data')
DUPLICATES = Path::PATH_DUPL

def read_set(file)
   File.open(file, 'r') do |file|
      s = Set.new
      file.readlines.each { |l| s << l }
      s
   end
end

rset = read_set(REDUCED)
dset = read_set(DUPLICATES)

fneg = dset-rset
fpos = rset-dset
tpos = dset&rset

puts "\nFALSE NEGATIVES"
puts "-----------------------------------------\n\n"
fneg.each { |f| puts f }

puts "\nFALSE POSITVIES"
puts "-----------------------------------------\n\n"
fpos.each { |f| puts f }

puts "\nTRUE POSITIVES"
puts "-----------------------------------------\n\n"
tpos.each { |f| puts f }