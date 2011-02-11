class Array
  def without_prefix!(prefix)
    map!{|x| x.start_with?(prefix) ? x[prefix.length .. -1] : x}
    self
  end
end
