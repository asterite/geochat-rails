class SignupNode < Node
  attr_accessor :suggested_login
  attr_accessor :group

  command do
    name 'name', 'signup'
    name 'n', :prefix => :required
    name "'", :prefix => :none, :space_after_command => false
    args :display_name
  end

  def initialize(attributes = {})
    super

    @suggested_login = @display_name.without_spaces if @display_name
  end

  def after_scan
    @display_name = @display_name[0 .. -2] if @display_name.end_with? "'"
    @display_name = @display_name.strip

    @suggested_login = @suggested_login[0 .. -2] if @suggested_login.end_with? "'"
    @suggested_login = @suggested_login.strip
  end

  def process
    return reply T.device_belongs_to_another_user if current_channel

    if @suggested_login.length < 2
      return reply T.cannot_signup_name_too_short(@suggested_login)
    end

    if @suggested_login.command?
      return reply T.cannot_signup_name_reserved(@suggested_login)
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
    reply T.welcome_to_geochat(user)
    reply T.remember_you_can_log_in(login, password)

    if @group
      join = JoinNode.new :group => @group
      join.pipeline = @pipeline
      join.process
    else
      reply T.to_send_message_to_a_group_you_must_first_join_one
    end
  end
end
