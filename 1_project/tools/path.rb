module Path
   extend self

   PATH_SCRIPT = __FILE__
   PATH_TOOLS  = File.dirname(PATH_SCRIPT)
   PATH_ROOT   = File.join(PATH_TOOLS,    '..')
   PATH_SOURCE = File.join(PATH_ROOT,     'src')
   PATH_QUEUE  = File.join(PATH_SOURCE,   'queue')
   PATH_DONE   = File.join(PATH_SOURCE,   'done')
   PATH_DATA   = File.join(PATH_ROOT,     'data')
   PATH_EVAL   = File.join(PATH_SOURCE,   'check.py')
   PATH_DUPL   = File.join(PATH_DATA,     'duplicates.txt')
   PATH_BEST   = File.join(PATH_DONE,     'best')
   PATH_LAST   = File.join(PATH_DONE,     'last')

   def root(path);   File.join(PATH_ROOT,    path); end
   def source(path); File.join(PATH_SOURCE,  path); end
   def tools(path);  File.join(PATH_TOOLS,   path); end
   def queue(path);  File.join(PATH_QUEUE,   path); end
   def done(path);   File.join(PATH_DONE,    path); end
   def data(path);   File.join(PATH_DATA,    path); end
end