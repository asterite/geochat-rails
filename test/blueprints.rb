require 'machinist/active_record'
require 'sham'
require 'ffaker'

Sham.short_name { Faker::Name.last_name.gsub(/[^0-9a-z]+/i, '').downcase }
Sham.name { Faker::Name.name }
Sham.title { Faker::Lorem.words.join }
Sham.description { Faker::Lorem.paragraph }
Sham.email { Faker::Internet.email }
Sham.url { "http://#{Faker::Internet.domain_name}" }
Sham.number { rand(8888) + 1111 }

User.blueprint do
  login { Sham.short_name }
  display_name { Sham.name }
end

Group.blueprint do
  send("alias") { Sham.short_name }
end

Channel.blueprint do
  user
  protocol { 'sms' }
  address { Sham.number }
end
