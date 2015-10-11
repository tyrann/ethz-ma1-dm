require 'thread'
require 'parallel'

#------------------------------------------------------------------------------
# Globals.
$mapper_id = 0

#------------------------------------------------------------------------------
# Directory paths.
SCRIPT_DIR  = File.dirname(__FILE__) 

#------------------------------------------------------------------------------
# File paths.
DATA        = File.join(SCRIPT_DIR, '../data/training.txt')
MAPPER      = File.join(SCRIPT_DIR, '../src/mapper_ut.py' )
REDUCER     = File.join(SCRIPT_DIR, '../src/reducer_ut.py')

#------------------------------------------------------------------------------
# Commands.
PYTHON      = 'python'
SORT        = 'sort'

# Creates a new string representing the original command piped into the 
# specified file.
# 
# ===Params:
# +command+:: The shell command to pipe.
# +file+::    The file to pipe the output into.
def pipe_to_file(command, file) 
   command + " >#{file}"       
end

# Creates a new string representing the first command piped into the second.
#
# ===Params:
# +command1+:: The output command.
# +command2+:: The input command.
def pipe_to(command1, command2) 
   command1 + ' | ' + command2 
end

# Creates a new string representing a command that will execute the specified
# python script.
#
# ===Params:
# +script+:: The script to execute.
# +input+::  The input to redirect.
def python(script, input) 
   "printf  \"#{input}\" | #{PYTHON} #{script}" 
end 

# Creates a new observer thread that show the current progress made.
#
# ===Params:
# +title+:: The title of the observer.
# +min+::   The minimum value.
# +max+::   The maximum value.
# +block+:: A block (current, min, max) => (current, stop)
def observer(title, min, max, &block)
   Thread.new do 
      c = 0
      f = true

      loop do
         if not f 
            print "\r"
         end

         c, s = block.call(c, min, max)

         print "#{title} : #{c}/#{max}"
         f = false

         break if s
         sleep(5)
      end
   end
end

#--------------------------------------------------------------------------
# SCRIPT


# The idea is simple. We read all the work lines from our training data and
# then forward the data to mappers and reducers in parallel.
work = File.open(DATA, 'r') do |data_file|
   text = data_file.read
   text.gsub!(/\r\n?/, "\n")
   text.lines.to_a
end

PROCS       = 8
LOAD        = work.length
CHUNKSIZE   = 5
CHUNKCOUNT  = LOAD/CHUNKSIZE

puts "Starting Map Reduce Process [N = #{LOAD}]"
puts "Dividing data into Chunks   [S = #{CHUNKSIZE}]"
puts "Setting up separate Chunks  [C = #{CHUNKCOUNT}]"
puts "Using multiple processes    [P = #{PROCS}]"

chunks = Array.new(CHUNKCOUNT)

(CHUNKCOUNT-1).times do |t|
   chunk_start = t * CHUNKSIZE
   chunks[t] = work.slice(
      chunk_start,
      CHUNKSIZE
   )
end

chunk_start = (CHUNKCOUNT-1)*CHUNKSIZE
chunk_size  = work.length - chunk_start
chunks[CHUNKCOUNT-1] = work.slice(
   chunk_start,
   chunk_size
)

puts "Last chunk size is bigger   [S = #{chunk_size}]"

result = Parallel.map(
   chunks, 
   :progress      => 'Mapping',
   :in_processes  => PROCS
) do |chunk|
   mapped = `#{python(MAPPER, chunk.join(' '))}`
   mapped.split("\n")
end

# We currently have an array of arrays which we need to flatten.
result.flatten!

puts "Finished mapping. [N = #{result.length}]"
