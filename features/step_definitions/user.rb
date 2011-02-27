Given /^a user with login "([^"]*)" and password "([^"]*)" exists$/ do |login, password|
  User.create! :login => login, :password => password
end

