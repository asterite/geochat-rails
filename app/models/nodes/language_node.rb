class LanguageNode < Node
  command do
    name 'lang'
    name '_', :prefix => :none, :space_after_command => false
    args :name
  end

  requires_user_to_be_logged_in

  def process
    locale = I18n.locale_for_language_name @name
    return reply :geochat_is_not_available_in_language, :args => @name unless locale

    I18n.with_locale locale do
      current_user.locale = locale
      current_user.save!

      reply T.language_changed
    end
  end
end
