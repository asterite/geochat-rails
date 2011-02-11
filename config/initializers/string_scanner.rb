class StringScanner
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
    case help
    when true
      if scan /^#{prefix}\s*#{names}(\s+(help|\?))?\s*$/i
        yield
      end
      return
    when :explicit
      if scan /^#{prefix}\s*#{names}\s+(help|\?)\s*$/i
        yield
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
