require_relative 'mr'
require_relative 'path'

mr = MapReduce::Instance.new(
   :instance      => Path::PATH_SOURCE,
   :mapper        => 'mapper_ut.py',
   :reducer       => 'reducer_ut.py',
   :store_map     => 'mapped.txt',
   :store_sort    => 'sorted.txt',
   :store_reduce  => 'reduced.txt',
   :data          => 'training.txt'
)

mr.run