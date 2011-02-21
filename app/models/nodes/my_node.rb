class MyNode < Node
  attr_accessor :key
  attr_accessor :value

  Groups = :groups
  Group = :group
  Name = :name
  Email = :email
  Login = :login
  Password = :password
  Number = :number
  Location = :location

  def self.scan(strscan)
    if strscan.scan /^\.*\s*my\s*$/i
      return HelpNode.new :node => MyNode
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)(help|\?)\s*$/i
      return HelpNode.new :node => MyNode
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)groups\s*$/i
      return MyNode.new :key => MyNode::Groups
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)(?:group|g)\s*$/i
      return MyNode.new :key => MyNode::Group
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)(?:group|g)\s+(?:@\s*)?(\S+)\s*$/i
      return MyNode.new :key => MyNode::Group, :value => strscan[1].strip
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)name\s*$/i
      return MyNode.new :key => MyNode::Name
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)name\s+(.+?)\s*$/i
      return MyNode.new :key => MyNode::Name, :value => strscan[1].strip
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)email\s*$/i
      return MyNode.new :key => MyNode::Email
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)email\s+(.+?)\s*$/i
      return MyNode.new :key => MyNode::Email, :value => strscan[1].strip
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)(number|phone|phonenumber|phone\s+number|mobile|mobilenumber|mobile\s+number)\s*$/i
      return MyNode.new :key => MyNode::Number
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)(number|phone|phonenumber|phone\s+number|mobile|mobilenumber|mobile\s+number)\s*(.+?)\s*$/i
      return MyNode.new :key => MyNode::Number, :value => strscan[1].strip
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)location\s*$/i
      return MyNode.new :key => MyNode::Location
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)location\s+(.+?)\s*$/i
      return MyNode.new :key => MyNode::Location, :value => strscan[1].strip.to_location
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)login\s*$/i
      return MyNode.new :key => MyNode::Login
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)login\s+(\S+)\s*$/i
      return MyNode.new :key => MyNode::Login, :value => strscan[1]
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)password\s*$/i
      return MyNode.new :key => MyNode::Password
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)password\s+(\S+)\s*$/i
      return MyNode.new :key => MyNode::Password, :value => strscan[1]
    end
  end
end
