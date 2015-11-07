require_relative 'path'

labels = File.open(Path.data('labels.txt'), 'w')
features = File.open(Path.data('features.txt'), 'w')

File.open(Path.data('training.txt')) do |f|
   f.each_line do |l|
      line  = l.split
      label = line[0]
      data  = line[1..-1]
      labels.puts(label)
      features.puts(data.join ' ')
   end
end