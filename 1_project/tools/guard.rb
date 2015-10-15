#!/usr/bin/ruby
#

require_relative 'path'
require_relative 'mr'

###############################################################################################
# Runs until the program is explicitly interrupted.
#
# Continually checks the queue folder for instances. If it finds an instance, it runs a map
# reduce instance on the instance and moves it to the done folder after reporting the evaluated
# values.
#
# The script keeps track of the implementation with the maximum fitness.
###############################################################################################

Q = Path::PATH_QUEUE
D = Path::PATH_DONE
P = File.join(D, 'max')
B = File.join(D, 'best')

m = File.open(P, 'r') { |f| f.gets.to_f }
p = true

loop do
   if p
      puts "----------------------------------------------------------"
      puts "Looking for unprocessed instances...\n"
   end

   i = Dir.entries(Q).delete_if { |e| e == '.' or e == '..' }
   p = !i.empty?

   while not i.empty?
      rel_path  = i.pop
      full_path = File.join(Q, rel_path)
      done_path = File.join(D, rel_path)
      puts "  -> Found an instance: #{rel_path}..."

      # Look for the mapper and reducer files in the instance.
      files    = Dir.entries(full_path)
      mappers  = files.select { |f| f.include? "mapper"} 
      reducers = files.select { |f| f.include? "reducer"}

      # If there is an ambiguity, go on to the next instance.
      next if mappers.length  > 1 or mappers.empty?
      next if reducers.length > 1 or reducers.empty?

      mr = MapReduce::Instance.new(
         :instance      => full_path,
         :mapper        => mappers[0],
         :reducer       => reducers[0],
         :store_map     => 'mapped.data',
         :store_sort    => 'sorted.data',
         :store_reduce  => 'reduced.data'
      )

      mr.run

      # Move the instance to the done folder.
      %x[mv #{full_path} #{done_path}]

      if mr.fitness > m
         m = mr.fitness
         File.open(P, 'w') { |f| f.puts m.to_s }

         %x[rm -rf #{B}]
         %x[cp -R #{done_path} #{B}]

         puts "New best solution found!"
      end
   end

   sleep(10)
end