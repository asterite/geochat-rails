module I18n
  def self.locale_names(locale)
    backend.translate(locale, "i18n.language.names").split(',').map &:strip
  rescue MissingTranslationData
    [locale.to_s]
  end

  def self.locale_name(locale)
    locale_names(locale).first
  end

  def self.locale_for_language_name(name)
    name = name.to_s

    available_locales.each do |locale|
      return locale if locale.to_s =~ /^#{name}$/i || locale_names(locale).any?{|x| x =~ /^#{name}$/i}
    end
    nil
  end
end
