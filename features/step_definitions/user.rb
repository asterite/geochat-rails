Given /^a user with login "([^"]*)" and password "([^"]*)" exists$/ do |login, password|
  User.create! :login => login, :password => password
end

Given /^a user with login "([^"]*)" is logged in$/ do |login|
  Then %Q(a user with login "#{login}" and password "secret" exists)
    And %Q(I go to the home page)
    And %Q(I fill in "Login" with "#{login}" within "#login")
    And %Q(I fill in "Password" with "secret" within "#login")
    And %Q(I press "Login")
end
