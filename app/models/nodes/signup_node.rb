class SignupNode < Node
  command

  attr_accessor :display_name
  attr_accessor :suggested_login
  attr_accessor :group

  def initialize(attributes = {})
    super

    self.suggested_login = self.display_name.without_spaces if self.display_name
  end

  Command = ::Command.new self do
    name 'name', 'signup'
    name 'n', :prefix => :required
    name "'", :prefix => :none, :space_after_command => false
    args :display_name
  end

  def after_scan
    self.display_name = self.display_name[0 .. -2] if self.display_name.end_with? "'"
    self.display_name = self.display_name.strip

    self.suggested_login = self.suggested_login[0 .. -2] if self.suggested_login.end_with? "'"
    self.suggested_login = self.suggested_login.strip
  end
end
