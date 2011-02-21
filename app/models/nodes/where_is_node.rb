class WhereIsNode < Node
  attr_accessor :user

  Command = ::Command.new self do
    name 'whereis', 'wh', 'w'
    args :user, :spaces_in_args => false
  end

  def after_scan
    self.user = self.user[0 .. -2] if self.user.end_with? '?'
  end
end
