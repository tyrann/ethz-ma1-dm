
###################################################################################
# CUSTOM
require_relative 'threaded'
require_relative 'shell'
require_relative 'work'
require_relative 'path'

include Work
include Threaded

module MapReduce
   class Instance
      # Initializes a new map reduce instance with the specified options.
      #
      # === Options:
      # :instance       [REQUIRED]: The folder in which the source lie.
      # :mapper         [OPTIONAL]: The name of the mapper file (default: "mapper.py")
      # :reducer        [OPTIONAL]: The name of the reducer file (default: "reducer.py")
      # :data           [OPTIONAL]: The name of the data file (default: "training.txt")
      # :store_map      [OPTIONAL]: The name of the mapper output file.
      # :store_reduce   [OPTIONAL]: The name of the reducer output file.
      # :store_sort     [OPTIONAL]: The name of the sorter output file.
      def initialize(options)
         @instance = options.fetch :instance, nil
         raise Exception.new 'No instance directory.' unless @instance
         raise Exception.new 'No instance directory.' unless File.exist? @instance

         # Python script construction lambdas.
         @mapper   = File.join(@instance, (options.fetch :mapper,  'mapper.py'))
         @reducer  = File.join(@instance, (options.fetch :reducer, 'reducer.py'))
         raise Exception.new 'Mapper does not exist.' unless File.exist? @mapper
         raise Exception.new 'Reducer does not exist.' unless File.exist? @reducer

         # Extract data path from options.
         @data = Path.data(options.fetch :data, 'training.txt')
         raise Exception.new 'Data does not exist.' unless File.exist? @data

         # Extract intermediate options.
         @st_map  = options.fetch :store_map,    false
         @st_red  = options.fetch :store_reduce, false 
         @st_sort = options.fetch :store_sort,   false

         @st_map  = File.join(@instance, @st_map)  if @st_map
         @st_red  = File.join(@instance, @st_red)  if @st_red
         @st_sort = File.join(@instance, @st_sort) if @st_sort
      end

      # Runs the map reduce instance.
      #
      # === Note:
      # This operation might take a lot of time, depending on the size
      # of the data set. This will also take up a lot of CPU power (ideally 100%
      # on all your cores), so make sure you know what you are doing.
      def run
         # MAPPING
         map_dist = Distributor.from_file @data, 65536
         map_exec = Executor.auto map_dist.work, 'Mapping'

         mapped = map_exec.script { Shell::Python.new @mapper }
         File.open(@st_map, 'w') { |f| f.write(mapped.join)} if @st_map 

         # SORTING
         sorted = mapped.group_by { |m| m.split(', ')[0] }

         if @st_sort
            File.open(@st_sort, 'w') { |f| f.write sorted.values.join }
         end

         # REDUCING
         red_dist = Distributor.from_list sorted, 65536
         red_exec = Executor.auto red_dist.work, 'Reducing'

         reduced = red_exec.script { Shell::Python.new @reducer }
         File.open(@st_red, 'w') { |f| f.write(reduced.join)} if @st_red

         # EVALUATING
         if @st_red
            cmd = Shell.python(Path::PATH_EVAL)
            cmd << " #{@st_red}"
            cmd << " #{Path::PATH_DUPL}"

            result = %x[#{cmd}].split "\n"
            puts result[0]
            puts result[1]
         end
      end
   end
end