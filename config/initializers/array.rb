class Array
  def without_prefix!(prefix)
    map!{|x| x.start_with?(prefix) ? x[prefix.length .. -1] : x}
    self
  end

  # Converts this array to a two elements array representing a loction.
  # If this array has two elements, the elements are to_f-ized.
  # If it has 6 elements then each 3 of them are treated as degrees, minutes and seconds.
  # If it has 8 elements then each 4 of them are treated as degrees, minutes, seconds and milliseconds
  # Otherwise this same array is returned.
  def to_location
    if self.length == 2
      self.map{|x| x.gsub(',', '.').to_f}
    elsif self.length == 6
      [self[0 .. 2].deg, self[3 .. 5].deg]
    elsif self.length == 8
      [self[0 .. 3].deg, self[4 .. 7].deg]
    else
      self
    end
  end

  # Converts this array to a float. It must have 3 or 4 elements,
  # which are treated as degrees, minutes, seconds and milliseconds.
  def deg
    args = self
    if args.length == 4
      args = [args[0], args[1], "#{args[2]}.#{args[3]}"]
    end
    first = args[0].to_f
    if first < 0
      -(-first + args[1].to_f / 60.0 + args[2].to_f / 3600.0)
    else
      first + args[1].to_f / 60.0 + args[2].to_f / 3600.0
    end
  end
end
