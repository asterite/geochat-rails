Feature: User can login

  Scenario: User successfully logs in
    Given a user with login "john" and password "doe" exists

    When I go to the home page
      And I fill in "Login" with "john" within "#login"
      And I fill in "Password" with "doe" within "#login"
      And I press "Login"

    Then I should see "Logout"

  Scenario: User can't log in, invalid user/password
    Given a user with login "john" and password "doe" exists

    When I go to the home page
      And I fill in "Login" with "john" within "#login"
      And I fill in "Password" with "incorrect" within "#login"
      And I press "Login"

    Then I should see "Invalid"
