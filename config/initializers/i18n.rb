module I18n
  def self.locale_name(locale)
    backend.translate(locale, "i18n.language.name")
  rescue MissingTranslationData
    locale.to_s
  end

  def self.locale_for_language_name(name)
    name = name.to_s

    available_locales.each do |locale|
      return locale if locale.to_s == name || locale_name(locale) == name
    end
    nil
  end
end
