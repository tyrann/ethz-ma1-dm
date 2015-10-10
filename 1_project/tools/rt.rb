require 'thread'
require 'open3'
require 'ruby-progressbar'

#------------------------------------------------------------------------------
# Globals.
$mapper_id = 0

#------------------------------------------------------------------------------
# Directory paths.
SCRIPT_DIR  = File.dirname(__FILE__) 

#------------------------------------------------------------------------------
# File paths.
DATA        = File.join(SCRIPT_DIR, '../data/training-small.txt')
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
def python(script) 
   "#{PYTHON} #{script}" 
end 

class Mapper

   # Initializes a new mapper.
   #
   # ===Note:
   # The mapper will use an external subprocess holding the python script
   # and the python instance. It will then forward all workload to that
   # python instance.
   def initialize(id)
      @id = id || 0
      @sc = MAPPER
   end

   # Starts working on a job queue.
   #
   # ===Params:
   # +queue+:: The job queue.
   def start(queue)
      i, o, e, t = Open3.popen3(PYTHON, @sc)
      @stdin  = i
      @stdout = o
      @stderr = e

      @stdin.sync = true

      @thread = Thread.new do 
         Thread.current[:output] = work(queue)
      end
   end

   # Gets the outputs of the mapper.
   #
   # ===Note:
   # This method blocks the calling thread until the mapper thread has
   # finished its work. It will then return an array of lines the mapper
   # has produced.
   def read()
      @thread.join
      @stdout.close
      @stderr.close

      @thread[:output]
   end

   # Works on a job in the current thread.
   #
   # ===Params:
   # +queue+:: The job queue.
   def work(queue)
      if @stdin.nil?    or 
         @stdout.nil?   or
         @stderr.nil?   then
         print "Could not establish connection.\n"

         Thread.current.stop
      end

      while not queue.empty?
         job = queue.pop

         @stdin.write job
      end

      @stdin.close
      @stdout.readlines
   end

   # Checks if the mapper is done.
   def done?()
      @thread.stop?
   end
end

#--------------------------------------------------------------------------
# SCRIPT

work_queue = Queue.new

# The idea is simple. We read all the work lines from our training data and
# then forward the data to mappers and reducers in parallel.
File.open(DATA, 'r') do |data_file|
   text = data_file.read
   text.gsub!(/\r\n?/, "\n")
   text.each_line {|l| work_queue << l}
end

puts "Starting Map Reduce Process [N = #{work_queue.length}]"

# Setup output and mappers.
results  = Array.new
mappers  = Array.new(8) {|i| Mapper.new i }

# Setup progress bar.
progress = Thread.new do 
   total   = work_queue.length
   current = total - work_queue.length

   bar = ProgressBar.create(
      :starting_at => 0,
      :total       => total,
      :title       => 'Mapping',
      :format      => '%t [%c/%C] |%B|'
   )

   while not work_queue.empty?
      sleep(1)
                        
      bar.progress = total - work_queue.length
      bar.refresh
   end
end

# Start the mappers and wait for results.
mappers.each { |m| m.start(work_queue) }
mappers.each { |m| results.concat m.read }

progress.join

puts results