class LanguageNode < Node
  command do
    name 'lang'
    name '_', :prefix => :none, :space_after_command => false
    args :name
  end

  def process
    reply 'Internationalization is not yet implemented'
  end
end
