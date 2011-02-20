class StringScanner
  def command(node, &block)
    command = Command.new node
    command.instance_eval(&block)

    no_args = command.args.length == 0 || command.args.any?{|x| x.last == {:optional => true}}

    command.names.each do |names|
      name_options = names.last
      if name_options.is_a?(Hash)
        names.pop
      else
        name_options = {}
      end

      names = names.join('|')
      names = "(#{names})"

      old_pos = self.pos

      # Check help names
      if scan /^\.*(?:help|h|\?)\s+\.*/i
        if scan /^#{names}\s*$/
          return HelpNode.new :node => node
        else
          self.pos = old_pos
        end
      end

      prefix = name_options[:prefix] == :required ? '\.+' : '\.*'

      old_pos = self.pos

      # If the string doesn't start with the command name, abort
      next unless scan /^#{prefix}\s*#{names}/i

      matched_name = self[1]

      # Special case: no arguments
      if no_args
        # This is the command
        if scan /^\s*$/i
          return command.node.new
        # This is the help
        elsif scan /^\s+(help|\?)\s*$/i
          return HelpNode.new :node => node
        end
      else
        # Check if help follows
        if command.help != :no
          if scan /^(\s+(help|\?))?\s*$/i
            return HelpNode.new :node => node
          end
        end
      end

      # A space must follow (if specified so)
      space_after_command = !name_options.has_key?(:space_after_command) || name_options[:space_after_command]
      space = space_after_command ? /^\s+/ : /\s*/

      if !scan space
        self.pos = old_pos
        next
      end

      # Now check arguments
      command.args.each do |args|
        args_options = args.last
        if args_options.is_a?(Hash)
          args = args[0 .. -2]
        else
          args_options = {}
        end

        spaces_in_args = !args_options.has_key?(:spaces_in_args) || args_options[:spaces_in_args]
        the_args = command_args args.length, spaces_in_args

        if scan the_args
          hash = Hash.new
          args.each_with_index do |name, i|
            hash[name.to_sym] = self[i + 1]
          end
          command.change_args.call hash, matched_name if command.change_args
          return command.node.new hash
        end

        # This is in case less then the required arguments were provided => show command help
        if command.args.length == 1
          1.upto(args.length - 1) do |new_length|
            the_args = command_args new_length, spaces_in_args

            if scan the_args
              return HelpNode.new :node => node
            end
          end
        end
      end

      self.pos = old_pos
    end
    nil
  end

  # Follows a small cache for matching number of arguments

  ArgsWithSpaces = {}
  ArgsWithoutSpaces = {}

  def command_args(num, spaces_in_args)
    if spaces_in_args
      existing = ArgsWithSpaces[num]
      return existing if existing

      the_args = Array.new(num, '(.+?)').join('\s+')
      the_args = /^#{the_args}\s*$/i
      ArgsWithSpaces[num] = the_args
    else
      existing = ArgsWithoutSpaces[num]
      return existing if existing

      the_args = Array.new(num, '(\S+?)').join('\s+')
      the_args = /^#{the_args}\s*$/i
      ArgsWithoutSpaces[num] = the_args
    end
  end

  class Command
    attr_reader :node
    attr_reader :names

    def initialize(node)
      @node = node
      @names = []
      @args = []
    end

    def name(*names)
      @names << names
    end

    def args(*options)
      if options.length == 0
        @args
      else
        @args << options
      end
    end

    def change_args(&block)
      if block_given?
        @change_args = block
      else
        @change_args
      end
    end

    def help(option = nil)
      if option
        @help = option
      else
        @help
      end
    end
  end
end
