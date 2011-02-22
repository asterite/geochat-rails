class SignupNode < Node
  command
  Help = "To signup in GeoChat send: name YOUR_NAME"

  attr_accessor :display_name
  attr_accessor :suggested_login
  attr_accessor :group

  def initialize(attributes = {})
    super

    @suggested_login = @display_name.without_spaces if @display_name
  end

  Command = ::Command.new self do
    name 'name', 'signup'
    name 'n', :prefix => :required
    name "'", :prefix => :none, :space_after_command => false
    args :display_name
  end

  def after_scan
    @display_name = @display_name[0 .. -2] if @display_name.end_with? "'"
    @display_name = @display_name.strip

    @suggested_login = @suggested_login[0 .. -2] if @suggested_login.end_with? "'"
    @suggested_login = @suggested_login.strip
  end

  def process
    return reply "This device already belongs to another user. To dettach it send: bye" if current_channel

    if @suggested_login.length < 2
      return reply "You cannot signup as '#{@suggested_login}' because it is too short (minimum is 2 characters)."
    end

    if @suggested_login.command?
      return reply "You cannot signup as '#{@suggested_login}' because it is a reserved name."
    end

    login = User.find_suitable_login @suggested_login
    password = PasswordGenerator.new_password

    if address2.integer?
      user = User.find_by_login_and_created_from_invite address2, true
      if user
        user.attributes = {:login => login, :display_name => @display_name, :password => password, :created_from_invite => false}
        user.save!
      end
    end

    if not user
      user = User.create! :login => login, :password => password, :display_name => @display_name
    end

    self.channel = create_channel_for user
    reply "Welcome #{user.display_name} to GeoChat! Send HELP for instructions. http://geochat.instedd.org"
    reply "Remember you can log in to http://geochat.instedd.org by entering your login (#{login}) and the following password: #{password}"

    if @group
      join = JoinNode.new :group => @group
      join.pipeline = @pipeline
      join.process
    else
      reply "To send messages to a group, you must first join one. Send: join GROUP"
    end
  end
end
