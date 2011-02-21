class LanguageNode < Node
  attr_accessor :name

  Command = ::Command.new self do
    name 'lang'
    name '_', :prefix => :none, :space_after_command => false
    args :name
  end
end
