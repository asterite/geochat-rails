Feature: User can configure an email channel

  Scenario: User configures an email channel
    Given a user with login "john" is logged in

    When I go to the new email channel page
      And I fill in "Email" with "john@doe.com"
      And I press "Configure"

    Then I should see "An email has been sent to john@doe.com"
      And "john@doe.com" should receive an email

    When "john@doe.com" opens the email
      And they click the first link in the email

    Then I should be on the channels page
      And I should see "Your email channel for john@doe.com is now active"
