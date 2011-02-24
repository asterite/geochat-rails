# This is to load every node at startup
Node

# Load all nodes
Dir["#{Rails.root}/app/models/nodes/*"].each do |file|
  eval(ActiveSupport::Inflector.camelize(file[file.rindex('/') + 1 .. -4]))
end
