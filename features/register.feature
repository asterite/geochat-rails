Feature: User can register

  Scenario: User successfully registers
    When I go to the home page
      And I fill in "Login" with "john" within "#register"
      And I fill in "Password" with "secret" within "#register"
      And I fill in "Password confirmation" with "secret" within "#register"
      And I press "Register"

    Then I should see "Logout"
