Feature: User can register

  Scenario: User successfully registers
    When I go to the home page
      And I fill in "Login" with "john" within "#register"
      And I fill in "Password" with "secret" within "#register"
      And I fill in "Password confirmation" with "secret" within "#register"
      And I press "Register"

    Then I should see "Logout"

  Scenario: User can't register login take
    Given a user with login "john" and password "doe" exists

    When I go to the home page
      And I fill in "Login" with "john" within "#register"
      And I fill in "Password" with "secret" within "#register"
      And I fill in "Password confirmation" with "secret" within "#register"
      And I press "Register"

    Then I should see "taken"

  Scenario: User can't register password confirmation does not match
    When I go to the home page
      And I fill in "Login" with "john" within "#register"
      And I fill in "Password" with "secret" within "#register"
      And I fill in "Password confirmation" with "not the same" within "#register"
      And I press "Register"

    Then I should see "doesn't match"
