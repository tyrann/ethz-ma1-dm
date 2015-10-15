require 'parallel'
require 'facter'

module Threaded
   def cpu_count
      Facter.value('processors')['count']
   end

   class Executor
      attr_reader :proc, :title

      # Initialize a new parallel executor.
      #
      # === Params:
      # +proc+::  The number of processes to use.
      # +work+::  The work the executor is working on.
      # +title+:: The title of the work.
      def initialize(proc, work, title)
         @proc  = proc
         @work  = work
         @title = title
      end

      # Returns the accumulated results from running the provided block
      # in parallel on the work set stored in the executor.
      #
      # === Params:
      # +block+:: The block to execute on each work item.
      def run(&block)
         Parallel.map(
            @work, 
            :in_processes  => @proc,
            :progress      => @title,
            &block
         ).flatten
      end

      # Returns the accumulated results from running a script object on
      # all working items in parallel. 
      #
      # === Params:
      # +implicit+:: A block taking no parameters, creating a new script instance.
      def script
         run do |item|
            script = yield
            script.start item
            script.await
         end
      end
   end

   class Executor
      private_class_method :new

      # Returns a new parallel executor.
      #
      # === Params:
      # +work+::  The work items to execute on.
      # +title+:: The title of the working set.
      #
      # === Note:
      # Will automatically decide on the number of cores to use.
      def self.auto(work, title)
         cores = cpu_count

         new cores, work, title
      end

      # Returns a new parallel executor.
      #
      # === Params:
      # +cores+:: The number of processes to use.
      # +work+::  The work items to execute on.
      # +title+:: The title of the working set.
      def self.cores(cores, work, title)
         new cores, work, title
      end
   end
end