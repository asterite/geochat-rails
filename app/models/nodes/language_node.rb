class LanguageNode < Node
  command do
    name 'lang'
    name '_', :prefix => :none, :space_after_command => false
    args :name
  end

  requires_user_to_be_logged_in

  def process
    locale = I18n.locale_for_language_name @name
    return reply T.geochat_is_not_available_in_language(@name) unless locale

    current_user.language = locale
    current_user.save!

    I18n.with_locale current_user.language do
      reply T.language_changed
    end
  end
end
