require 'machinist/active_record'
require 'sham'
require 'ffaker'

Sham.short_name { Faker::Name.name.gsub(/[^0-9a-z]+/i, '').downcase }
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


Membership.blueprint do
  group
  user
  role { :owner }
end

SmsChannel.blueprint do
  user
  address { Sham.number }
  status { :on }
end

[EmailChannel, XmppChannel].each do |clazz|
  clazz.blueprint do
    user
    address { Sham.email }
    status { :on }
  end
end

Message.blueprint do
  text { Sham.title }
  group
  sender
  lat
  lon
  location { Sham.title }
end
