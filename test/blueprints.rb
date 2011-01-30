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
Sham.lat { -90 + rand(180) + rand(10000)/10000}
Sham.lon { -180 + rand(360) + rand(10000)/10000}

User.blueprint do
  login { Sham.short_name }
  password { Sham.short_name }
  display_name { Sham.name }
  lat
  lon
  location { Sham.title }
end

Group.blueprint do
  send("alias") { Sham.short_name }
  name
end

Channel.blueprint do
  user
  protocol { 'sms' }
  address { Sham.number }
end

Message.blueprint do
  text { Sham.title }
  group
  sender
  lat
  lon
  location { Sham.title }
end
