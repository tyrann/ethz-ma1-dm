require_relative 'mr'
require_relative 'path'

mr = MapReduce::Instance.new(
   :instance         => Path::PATH_SOURCE,
   :mapper           => 'mapper_debug.py',
   :reducer          => 'reducer_debug.py',
   :data             => 'false-positive.txt',
   :store_map        => 'mapper_debug.txt',
   :store_reduce     => 'reducer_debug.txt',
   :store_sort       => 'sort_debug.txt'
)

mr.run