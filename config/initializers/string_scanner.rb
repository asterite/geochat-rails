class StringScanner
  def command(node, &block)
    command = Command.new node
    command.instance_eval(&block)

    command.args :none if command.args.length == 0

    command.names.each do |names|
      name_options = names.last
      if name_options.is_a?(Hash)
        names.pop
      else
        name_options = {}
      end

      prefix = case name_options[:prefix]
               when nil, :optional
                 '\.*'
               when :required
                 '\.+'
               end

      names = names.join('|')
      names = "(?:#{names})"

      if command.args == [[:none]]
        if scan /^#{prefix}\s*#{names}\s+(help|\?)\s*$/i
          return HelpNode.new :node => node
        end
      else
        if command.help != :no
          if scan /^#{prefix}\s*#{names}(\s+(help|\?))?\s*$/i
            return HelpNode.new :node => node
          end
        end
      end

      command.args.each do |args|
        args_options = args.last
        if args_options.is_a?(Hash)
          args = args[0 .. -2]
        else
          args_options = {}
        end
        spaces_in_args = !args_options.has_key?(:spaces_in_args) || args_options[:spaces_in_args]

        if args[0] == :none || args_options[:optional]
          if scan /^#{prefix}\s*#{names}\s*$/i
            return command.node.new
          end
        end

        if args[0] != :none
          spaces_in_args = !args_options.has_key?(:spaces_in_args) || args_options[:spaces_in_args]
          space_after_command = !name_options.has_key?(:space_after_command) || name_options[:space_after_command]
          space = space_after_command ? '\s+' : '\s*'

          arg = spaces_in_args ? '(.+?)' : '(\S+)'
          the_args = Array.new(args.length, arg).join('\s+')

          #p "^#{prefix}\\s*#{names}#{space}#{the_args}\\s*"

          if scan /^#{prefix}\s*#{names}#{space}#{the_args}\s*$/i
            hash = Hash.new
            args.each_with_index do |name, i|
              hash[name.to_sym] = self[i + 1]
            end
            if command.change_args
              command.change_args.call hash
            end
            return command.node.new hash
          end

          if command.args.length == 1
            1.upto(args.length - 1) do |new_length|
              arg = spaces_in_args ? '(.+?)' : '(\S+)'
              the_args = Array.new(new_length, arg).join('\s+')

              if scan /^#{prefix}\s*#{names}#{space}#{the_args}\s*$/i
                return HelpNode.new :node => node
              end
            end
          end
        end
      end
    end
    nil
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

  def scan_command(*names, &block)
    options = names.last
    if options.is_a?(Hash)
      names.pop
    else
      options = {}
    end

    prefix = case options[:prefix]
      when nil, :optional
        '\.*'
      when :required
        '\.+'
    end

    names = names.join('|')
    names = "(?:#{names})"

    help = options[:help]
    if help
      case help
      when true
        yield if scan /^#{prefix}\s*#{names}(\s+(help|\?))?\s*$/i
      when :explicit
        yield if scan /^#{prefix}\s*#{names}\s+(help|\?)\s*$/i
      end
      return
    end

    if block.arity == 0
      if scan /^#{prefix}\s*#{names}\s*$/i
        yield
      end
    else
      spaces_in_args = !options.has_key?(:spaces_in_args) || options[:spaces_in_args]
      space_after_command = !options.has_key?(:space_after_command) || options[:space_after_command]
      space = space_after_command ? '\s+' : '\s*'

      arg = spaces_in_args ? '(.+?)' : '(\S+)'
      args = Array.new(block.arity, arg).join('\s+')
      if scan /^#{prefix}\s*#{names}#{space}#{args}\s*$/i
        yield *Array.new(block.arity) {|i| self[i + 1]}
      end
    end
  end
end
