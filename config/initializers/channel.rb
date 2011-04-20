# This is to load every channel at startup
Channel

# Load all channels
Dir["#{Rails.root}/app/models/channels/*"].each do |file|
  eval(ActiveSupport::Inflector.camelize(file[file.rindex('/') + 1 .. -4]))
end
