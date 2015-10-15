
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
      attr_reader :fitness
      attr_reader :precision
      attr_reader :recall

      attr_reader :true_positives
      attr_reader :false_positives
      attr_reader :false_negatives

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
         @fitness   = 0.0
         @precision = 0.0
         @recall    = 0.0

         @true_positives  = 0
         @false_positives = 0
         @false_negatives = 0

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
         cmd = Shell.python(Path::PATH_EVAL)
         cmd << " #{@st_red}"
         cmd << " #{Path::PATH_DUPL}"
         result = %x[#{cmd}].split "\n"

         puts result[0]
         puts result[1]

         # EXTRACT EVALUATION VALUES
         result[0].match /TP = (?<tp>\d+) FP = (?<fp>\d+) FN = (?<fn>\d+)/
         @true_positives  = Regexp.last_match[:tp].to_i
         @false_positives = Regexp.last_match[:fp].to_i
         @false_negatives = Regexp.last_match[:fn].to_i

         result[1].match /Precision = (?<p>\d+\.\d+), Recall = (?<r>\d+\.\d+), F = (?<f>\d+\.\d+)/
         @fitness   = Regexp.last_match[:f].to_f
         @precision = Regexp.last_match[:p].to_f
         @recall    = Regexp.last_match[:r].to_f
      end
   end
end