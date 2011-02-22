class LanguageNode < Node
  command

  attr_accessor :name

  Command = ::Command.new self do
    name 'lang'
    name '_', :prefix => :none, :space_after_command => false
    args :name
  end

  def process
    reply 'Internationalization is not yet implemented'
  end
end
