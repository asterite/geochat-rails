# coding: utf-8

require 'test_helper'

class I18nTest < ActiveSupport::TestCase
  ['es', 'Es', 'Spanish', 'spanish', 'Espanol', 'espanol', 'Español', 'español'].each do |name|
    test "locale for language name #{name}" do
      assert_equal :es, I18n.locale_for_language_name(name)
    end
  end

  ['English', 'english', 'ingles', 'inglés'].each do |name|
    test "locale for language name #{name}" do
      assert_equal :en, I18n.locale_for_language_name(name)
    end
  end
end
