Bitly.use_api_version_3
BitlyConfig = YAML.load_file(File.expand_path('../../../config/bitly.yml', __FILE__))[Rails.env]

class Bitly
  def self.new_from_config
    Bitly.new BitlyConfig['username'], BitlyConfig['api_key']
  end
end
