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
DUPLICATES  = File.join(SCRIPT_DIR, '../data/duplicates.txt')
DATA        = File.join(SCRIPT_DIR, '../data/training.txt'  )
MAPPER      = File.join(SCRIPT_DIR, '../src/mapper_ut.py'   )
REDUCER     = File.join(SCRIPT_DIR, '../src/reducer_ut.py'  )
CHECKER     = File.join(SCRIPT_DIR, '../src/check.py'       )
TEMP_MAP    = File.join(SCRIPT_DIR, 'temp_map'              )
TEMP_SORT   = File.join(SCRIPT_DIR, 'temp_sort'             )
TEMP_REDUCE = File.join(SCRIPT_DIR, 'temp_reduce'           )

#------------------------------------------------------------------------------
# Commands.
PYTHON      = 'python'
SORT        = 'sort'

# Creates a new string representing the original command piped into the 
# specified file and piped from the specified file.
# 
# ===Params:
# +command+:: The shell command to pipe.
# +input+::   The file to take input from.
# +output+::  The file to pipe the output into.
def pipe_file(command, input, output) 
   res = command
   res << " <#{input}" if input and not input.empty?
   res << " >#{output}" if output and not output.empty?
   res
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
def python(script, input=nil)
   return "printf  \"#{input}\" | #{PYTHON} #{script}" if input
   return "#{PYTHON} #{script}"
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

puts "Starting Map Reduce Process   [N = #{LOAD}]"
puts "Dividing data into Chunks     [S = #{CHUNKSIZE}]"
puts "Setting up separate Chunks    [C = #{CHUNKCOUNT}]"
puts "Using multiple processes      [P = #{PROCS}]"

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

puts "Last chunk size is bigger     [S = #{chunk_size}]"

# Since we allready start a subprocess, using parallel here might not
# do anything for us. I am pretty sure we could just write to all our
# subprocesses, close all their standard input
result = Parallel.map(
   chunks, 
   :progress      => 'Mapping',
   :in_processes  => PROCS
) do |chunk|
   IO.popen(python(MAPPER), 'r+') do |pipe|
      chunk.each {|l| pipe.puts l}
      pipe.close_write
      pipe.read.split("\n")
   end
end

# We currently have an array of arrays which we need to flatten.
result.flatten!

puts "Finished mapping.             [N = #{result.length}]"
puts "Writing the mapped values     [F = #{TEMP_MAP}]"
File.open(TEMP_MAP, 'w') { |f| f.write(result.join "\n")}

# The next step is sorting the received data. To do so, we use the ruby
# sorting capabilities. This is nothing we can do in parallel.
puts "Sorting the mapped values     [F = #{TEMP_SORT}]"
result.collect! {|l| l.split(', ')}
groups = result.group_by { |l| l[0] }

# Print the sorted values into a temporary file.
File.open(TEMP_SORT, 'w') do |f|
   groups.each do |key, values|
      lines = values.map { |v| "#{v[0]}, #{v[1]}" }
      f.write "#{lines.join("\n")}\n"
   end
end

# The last step, which can be done in parallel again is reducing.
# To do so, we first need to separate the sorted values into chunks.
RMAXCHUNKSIZE = 100

chunks = []
load   = []
groups.each do |key, values|
   chunk = values.map { |v| "#{v[0]}, #{v[1]}"}
   load.concat chunk
   
   # Check if the chunk is large enough and finalize it if so.
   if load.length >= RMAXCHUNKSIZE
      chunks << load.compact
      load = []
   end
end

# We extract some information from these chunks for debugging purposes.
# We want to know the maximum chunk size, the minimum chunk size and
# the average chunk size.
NCHUNKS = chunks.length
min     =  Float::INFINITY
max     = -Float::INFINITY
avg     = 0.0

chunks.each do |c|
   len = c.length
   min = len if len < min
   max = len if len > max
   avg = avg + len.to_f/NCHUNKS
end

puts "The values have been sorted   [C = #{NCHUNKS}]"
puts "The minimum chunk size is     [S = #{min}]"
puts "The maximum chunk size is     [S = #{max}]"
puts "The average chunk size is     [S = #{avg}]"
puts "Reducing the chunks           [R = #{REDUCER}]"

result = Parallel.map(
   chunks, 
   :progress      => 'Reducing',
   :in_processes  => PROCS
) do |chunk|
   IO.popen(python(REDUCER), 'r+') do |pipe|
      chunk.each {|l| pipe.puts l}
      pipe.close_write
      pipe.read.split("\n")
   end
end

result.flatten!

puts "The values have been reduced  [N = #{result.length}]"
puts "Writing results to file       [R = #{TEMP_REDUCE}]"
File.open(TEMP_REDUCE, 'w') { |f| f.write(result.join "\n") }

puts "Running check against true duplicates!"
puts "----------------------------------------------------"
puts ""
puts `python #{CHECKER} #{TEMP_REDUCE} #{DUPLICATES}`
