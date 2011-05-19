class Command
  attr_reader :node
  attr_reader :names
  attr_accessor :args_optional

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

  def args(*args)
    return @args if args.length == 0

    args_options = args.extract_options!

    self.args_optional = true if args_options.has_key?(:optional) && args_options[:optional]
    spaces_in_args = !args_options.has_key?(:spaces_in_args) || args_options[:spaces_in_args]
    the_args = command_args args.length, spaces_in_args

    @args << {:args => args, :regex => the_args, :spaces => spaces_in_args}
  end

  def scan(strscan)
    no_args = self.args.length == 0 || self.args_optional

    self.names.each do |name|
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
        if strscan.scan /^(\s+(help|\?))?\s*$/i
          return HelpNode.new :node => node
        end
      end

      # A space must follow (if specified so)
      if !strscan.scan name[:space]
        strscan.pos = old_pos
        next
      end

      # Now check arguments
      self.args.each do |args|
        if strscan.scan args[:regex]
          hash = {:matched_name => matched_name}
          args[:args].each_with_index do |name, i|
            hash[name.to_sym] = strscan[i + 1]
          end
          return self.node.new hash
        end

        # This is in case less then the required arguments were provided => show command help
        if self.args.length == 1
          1.upto(args[:args].length - 1) do |new_length|
            the_args = command_args new_length, args[:spaces]

            return HelpNode.new :node => node if strscan.scan the_args
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
      cache = ArgsWithSpaces
      match = '(.+?)'
    else
      cache = ArgsWithoutSpaces
      match = '(\S+?)'
    end

    existing = cache[num]
    return existing if existing

    the_args = Array.new(num, match).join('\s+')
    the_args = /^#{the_args}\s*$/i
    cache[num] = the_args
  end
end
