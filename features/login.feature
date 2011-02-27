Feature: User can login

  Scenario: User successfully logs in
    Given a user with login "john" and password "doe" exists

    When I go to the home page
    And I fill in "Login" with "john"
    And I fill in "Password" with "doe"
    And I press "Login"

    Then I should see "Logout"

  Scenario: User can't log in, invalid user/password
    Given a user with login "john" and password "doe" exists

    When I go to the home page
    And I fill in "Login" with "john"
    And I fill in "Password" with "incorrect"
    And I press "Login"

    Then I should see "Invalid"
