class Command
  attr_reader :node
  attr_reader :names

  def initialize(node, &block)
    @node = node
    @names = []
    @args = []
    instance_eval(&block) if block_given?
  end

  def name(*names)
    name_options = names.last
    if name_options.is_a?(Hash)
      names.pop
    else
      name_options = {}
    end

    names = names.join '|'
    names = "(#{names})"

    prefix = name_options[:prefix] == :required ? '\.+' : '\.*'

    space_after_command = !name_options.has_key?(:space_after_command) || name_options[:space_after_command]
    space = space_after_command ? /^\s+/ : /\s*/

    @names << ({
      :regex => /^#{prefix}\s*#{names}/i,
      :regex_end => /^\s*\.*#{names}\s*$/i,
      :space => space
    })
  end

  def args(*options)
    if options.length == 0
      @args
    else
      @args << options
    end
  end

  def help(option = nil)
    if option
      @help = option
    else
      @help
    end
  end

  def scan(strscan)
    no_args = self.args.length == 0 || self.args.any?{|x| x.last == {:optional => true}}

    self.names.each do |name|
      old_pos = strscan.pos

      old_pos = strscan.pos

      # If the string doesn't start with the command name, abort
      next unless strscan.scan name[:regex]

      matched_name = strscan[1]

      # Special case: no arguments
      if no_args
        # This is the command
        if strscan.scan /^\s*$/i
          return self.node.new
          # This is the help
        elsif strscan.scan /^\s+(help|\?)\s*$/i
          return HelpNode.new :node => node
        end
      else
        # Check if help follows
        if self.help != :no
          if strscan.scan /^(\s+(help|\?))?\s*$/i
            return HelpNode.new :node => node
          end
        end
      end

      # A space must follow (if specified so)
      if !strscan.scan name[:space]
        strscan.pos = old_pos
        next
      end

      # Now check arguments
      self.args.each do |args|
        args_options = args.last
        if args_options.is_a?(Hash)
          args = args[0 .. -2]
        else
          args_options = {}
        end

        spaces_in_args = !args_options.has_key?(:spaces_in_args) || args_options[:spaces_in_args]
        the_args = command_args args.length, spaces_in_args

        if strscan.scan the_args
          hash = {:matched_name => matched_name}
          args.each_with_index do |name, i|
            hash[name.to_sym] = strscan[i + 1]
          end
          return self.node.new hash
        end

        # This is in case less then the required arguments were provided => show command help
        if self.args.length == 1
          1.upto(args.length - 1) do |new_length|
            the_args = command_args new_length, spaces_in_args

            if strscan.scan the_args
              return HelpNode.new :node => node
            end
          end
        end
      end

      strscan.pos = old_pos
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
end
