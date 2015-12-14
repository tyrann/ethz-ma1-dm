module Shell
   extend self 

   # Returns a string representing a shell command piping the specified
   # input file into the specified command and piping the output of said
   # command into the specified output file.
   # 
   # ===Params:
   # +command+:: The shell command to pipe.
   # +input+::   The file to take input from.
   # +output+::  The file to pipe the output into.
   def pipe_file(command, input = nil, output = nil) 
      res = command
      res << " <#{input}" if input and not input.empty?
      res << " >#{output}" if output and not output.empty?
      res
   end

   # Returns a string representing a shell command piping the output of the
   # first command to the input of the second command.
   #
   # ===Params:
   # +command1+:: The output command.
   # +command2+:: The input command.
   def pipe_to(command1, command2) 
      command1 + ' | ' + command2 
   end

   # Returns a string representing a shell command executing a python script.
   # Will pass the specified string to the standard input of the python script
   # if specified, else the standard input is left untouched.
   #
   # ===Params:
   # +script+:: The script to execute.
   # +input+::  The input to redirect.
   def python(script, input = nil)
      return "printf  \"#{input}\" | python #{script}" if input
      return "python #{script}"
   end 

   class Python
      # Initializes a new python process for the specified script.
      #
      # === Params:
      # +script+:: The script to wrap.
      def initialize(script)
         @script  = script
         @command = Shell.python script
         @running = false
      end

      # Executes the script by piping the specified file ot the standard
      # input.
      #
      # === Params:
      # +file+:: The file to pipe to the standard input.
      def pipe_in(file)
         cmd = pipe_file @command, file
         %x[#{cmd}].split "\n"
      end

      # Executes the script and pipes all output to the specified file.
      #
      # === Params:
      # +file+:: The file to pipe the output to.
      def pipe_out(file)
         cmd = pipe_file @command, nil, file
         %x[#{cmd}]
      end

      # Executes the script by piping input from the specified input file
      # to the standard input and piping the output of the script into the
      # specified output file.
      #
      # === Params:
      # +input+::    The path to the file to pipe in.
      # +output+::   The path to teh file to pipe to.
      def pipe_in_out(input, output)
         cmd = pipe_file @command, input, output
         %x[#{cmd}]
      end

      # Starts execution of the script and pipes in the provided input.
      #
      # === Note:
      # Will raise an exception if the script has been started but not
      # yet been read from. We can not pipe new input into the script
      # after the input pipe has been closed and we can not read from
      # the script before the input pipe has been closed.
      def start(input)
         raise Exception.new 'Script is already running.' if @running

         @input = [input] if input.is_a? String
         @input = input   if input.is_a? Chunk

         @proc = IO.popen(@command, 'r+')
         @input.each { |item| @proc.puts item }
         @proc.close_write

         @running = true
      end

      # Waits for the end of the script execution and reads the output.
      #
      # === Note:
      # Will raise an exception if the script has not been started yet.
      # We can not read from a script until all input has been piped into
      # it.
      def await
         raise Exception.new 'Script is not running.' unless @running

         output = @proc.readlines
         @proc.close_read
         @running = false
         
         output
      end
   end
end