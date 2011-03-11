class Numeric
  def to_lat
    to_coord 'S', 'N'
  end
  
  def to_lon
    to_coord 'W', 'E'
  end
  
  def to_coord(neg, pos)
    "#{self.abs.round(5).to_s} #{self < 0 ? neg : pos}"
  end
end