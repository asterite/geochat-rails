class String
  # Does this string represent an integer?
  def integer?
    Integer(self) rescue nil
  end

  def email?
    self =~ ValidatesEmailFormatOf::Regex
  end

  def levenshtein(other)
    other = other.to_s
    distance = Array.new(self.size + 1, 0)
    0.upto(self.length) do |i|
      distance[i] = Array.new(other.size + 1)
      distance[i][0] = i
    end
    0.upto(other.size) do |j|
      distance[0][j] = j
    end

    1.upto(self.size) do |i|
      1.upto(other.size) do |j|
        distance[i][j] = [distance[i - 1][j] + 1,
                          distance[i][j - 1] + 1,
                          distance[i - 1][j - 1] + ((self[i - 1] == other[j - 1]) ? 0 : 1)].min
      end
    end
    distance[self.size][other.size]
  end

  # Returns a new string with spaces removed (everywhere).
  def without_spaces
    gsub(/\s/, '')
  end

  # Returns a channel class for this protocol
  def to_channel
    value = self == 'mailto' ? 'email' : self
    "#{value}_channel".camelize.constantize
  end

  NumericLocationNum = "(\\d+(?:(?:\\.|,)\\d+)?)"
  NumericLocationSep = "(?:\\s+|\\s*(?:,|\\.|\\*)\\s*)"
  NumericLocation = /^\s*#{NumericLocationNum}#{NumericLocationSep}#{NumericLocationNum}\s*$/

  # If this string denotes a numeric location, a two element array is returned
  # with it. Otherwise this string is returned.
  def to_location
    if self =~ NumericLocation
      [$1, $2].to_location
    else
      self
    end
  end

  # Returns the command associated to this string, if any, or nil.
  def command
    Node::Commands.each do |cmd|
      cmd.names.each do |name|
        if self =~ name[:regex_end]
          return cmd
        end
      end
    end

    self =~ /^none$/i
  end

  alias_method :command?, :command

  def shorten_urls!
    gsub! /http:\/\/[^\s,]+/i do |url|
      last_index = url.length - 1
      last_index -= 1 while ['.', ','].include?(url[last_index .. last_index])
      short = Googl.shorten url[0 .. last_index]
      "#{short}#{url[last_index + 1 .. -1]}"
    end
  end
end
