module ApplicationHelper
  def geochat_version
    begin
      @@geochat_version = File.read('VERSION').strip unless defined? @@geochat_version
    rescue Errno::ENOENT
      @@geochat_version = 'Development'
    end
    @@geochat_version
  end
end
