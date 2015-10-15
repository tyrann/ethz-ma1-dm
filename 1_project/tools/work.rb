require 'thread'

module Work

   class Chunk
      include Enumerable

      attr_reader :capacity
      attr_reader :current
      attr_reader :count
      attr_reader :items

      # Initializes a new chunk with a specified capacity.
      #
      # === Params:
      # +capacity+:: The desired capacity of the chunk.
      #
      # === Note:
      # The capacity is not enforced.
      def initialize(capacity)
         @capacity = capacity
         @current  = 0
         @count    = 0
         @items    = []
      end

      # Returns true, if the item fits into the chunks, false else.
      def fit?(item)
         b = case item
         when String; item.length * 4
         when Array;  item.reduce(0) { |s, i| s + i.length * 4 }
         end
         b < @capacity - @current
      end

      # Returns true, if the buffer is empty, false else.
      def empty?
         @count == 0
      end

      # Adds an item to the chunk.
      # 
      # === Params:
      # +item+:: The item to add.
      #
      # === Note:
      # Will not fail if the item is too big, but will emit a warning.
      def add(item)
         if not fit? item 
            $stderr.write "Oversize Chunk: [ #{@current} / #{@capacity} ]\n"
         end

         b = item.length * 4
         @current += b
         @count   += 1
         @items   << item
      end

      # Clears the chunk from all items.
      def clear
         @items = []
         @current = 0
         @count   = 0
      end

      # Apply a block to all elements of this chunk.
      #
      # === Params:
      # +block+:: The block to apply to all elements.
      def each(&block)
         @items.each(&block)
      end
   end

   class Distributor
      attr_reader :chunk_count
      attr_reader :chunk_size
      attr_reader :work_size
      attr_reader :item_count

      # Initializes a new distributor which will distribute work into
      # chunks of the specified size in bytes. The size will only be
      # approximated, so the chunksize is more of a guidance than an
      # explicit bound.
      #
      # === Params:
      # +chunk_size+:: The size per chunk in bytes.
      def initialize(chunk_size = 4096)
         @chunk_count  = 0
         @chunk_size   = chunk_size
         @work_queue   = Queue.new
         @work_array   = Array.new
         @work_size    = 0
         @item_count   = 0
      end

      # Returns true, if there are work items on the queue, false else.
      def has_work?
         not @work_queue.empty?
      end

      # Returns the next work item the distributor has available.
      #
      # === Note:
      # This method is thread safe and is intended to be used to distribute
      # work among multiple threads which access the distributor at the same
      # time.
      def next
         @work_queue.deq
      end

      # Returns all work items untouched.
      #
      # === Note:
      # This method is not thread safe and must be synchronized explicitly,
      # if used from withing threads.
      def work
         @work_array
      end

      # Fills the distributor work queue with work. Automatically divides the
      # work into the specified amount of chunks.
      #
      # === Params:
      # +work+:: The work items to distribute among workers.
      def provide(work)
         raise Exception.new 'Work has already been provided.' if has_work?
         raise Exception.new 'Work must be a list of items.'   if not work.respond_to? :length

         # We need to check if the work is a hash. If so, we need to make sure
         # values with the same keys are hashed in the same chunk.
         provide_hash(work) if work.is_a? Hash
         provide_list(work) if work.is_a? Array

         @chunk_count = @work_array.length
      end

      # Provides a list as work.
      #
      # === Params:
      # +work+:: A list of work items.
      def provide_list(work)
         # Calculate the size of the whole work in bytes.
         # For this calculation we assume each character to be stored as 4 bytes.
         @work_size = work.reduce(0){ |s, i| s + i.length } * 4
         buffer     = Chunk.new @chunk_size

         work.each do |w|
            if not buffer.fit? w and buffer.empty?
               # The work item is bigger than the desired chunk size.
               # We just push it in its own chunk and hope for the best.
               # Emit a warning though.

               buffer.add w
               @work_queue << buffer.clone
               @work_array << buffer.clone
               @item_count += buffer.count

               buffer.clear
               next
            end

            if not buffer.fit? w
               # The new item does not fit into the current chunk.
               # Emit current chunk and put work item in a new chunk.
               @work_queue << buffer.clone
               @work_array << buffer.clone
               @item_count += buffer.count

               buffer.clear
               buffer.add w
               next
            end

            buffer.add w
         end

         if not buffer.empty?
            @work_queue << buffer.clone
            @work_array << buffer.clone
            @item_count += buffer.count
         end
      end

      # Provides a hash of work items.
      #
      # === Params:
      # +work+:: A hash of work items.
      def provide_hash(work)
         work.each { |k, v| @work_size += v.reduce(0) { |s, i| s + i.length } }

         buffer = Chunk.new @chunk_size
         work.each do |k, w|
            if not buffer.fit? w and buffer.empty?
               # We have an oversized chunk. We simply do not care at this point,
               # just add all the items to the new buffer and hope for the best.

               w.each { |v| buffer.add v }
               @work_queue << buffer.clone
               @work_array << buffer.clone
               @item_count += buffer.count

               buffer.clear
               next
            end

            if not buffer.fit? w
               # The new item does not fit into the current chunk.
               # Emit the current chunk and put the work item into a new chunk.
               @work_queue << buffer.clone
               @work_array << buffer.clone
               @item_count += buffer.count

               buffer.clear
               w.each { |v| buffer.add v }
               next
            end

            w.each { |v| buffer.add v }
         end

         if not buffer.empty?
            @work_queue << buffer.clone
            @work_array << buffer.clone
            @item_count += buffer.count
         end
      end

      private :provide_list
      private :provide_hash
   end

   class Distributor
      private_class_method :new

      # Creates a new distributor for the specified file of work.
      #
      # === Params:
      # +work_file+::   The work file to load data from.
      # +chunk_size+::  The size of each chunk in bytes.
      #
      # === Note: 
      # The work items are assumed to be split by line. This will create the work
      # items by reading the file line by line.
      def self.from_file(work_file, chunk_size)
         work = File.open(work_file, 'r') do |data_file|
            text = data_file.read
            text.gsub!(/\r\n?/, "\n")
            text.split "\n"
         end

         Distributor.from_list work, chunk_size
      end

      # Creates a new distributor for the specified work string.
      #
      # === Params:
      # +work_string+:: The work string to read data from.
      # +chunk_size+::  The size of each chunk in bytes.
      #
      # === Note:
      # The work items are assumed to be split by new line characters.
      def self.from_string(work_string, chunk_size)
         Distributor.from_list (work_string.split "\n"), chunk_size
      end

      # Creates a new distributor for the specified list of work items.
      #
      # === Params:
      # +work+::        A list of work items for the distributor.
      # +chunk_size+::  The size of each chunk in bytes.
      def self.from_list(work, chunk_size)
         distributor = new chunk_size
         distributor.provide work
         distributor
      end
   end

end