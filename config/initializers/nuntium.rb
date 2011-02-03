NuntiumConfig = YAML.load_file(File.expand_path('../../../config/nuntium.yml', __FILE__))[Rails.env]

class Nuntium
  def self.new_from_config
    Nuntium.new NuntiumConfig['url'], NuntiumConfig['account'], NuntiumConfig['application'], NuntiumConfig['password']
  end
end
