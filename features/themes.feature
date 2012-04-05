Feature: What Theme
  In order to provide information about a theme
  As a developer
  I need to provide an api for requesting information about themes

  @pending
  Scenario: API Home should list Documentation for API
    Given PENDING I am on the home page
    Then  I should see "Documentation"

  Scenario: JSON should be the default format
    Given I am on the themes page
    Then  the page should be in "json" format

  Scenario: Should return theme information using Stylesheets
    Given I discover theme information for "nikhgupta.com"
    Then  I should see "Quattro"

  Scenario: Should return theme information using Introspection
    Given I discover theme information for "wordpress.com"
    Then  I should see ":true"
    Then  I should see "h4"

  Scenario: Should return error state when a theme can not be discovered
    Given I discover theme information for "wordpress.org"
    Then  I should see ":false"
    And   I should see "customized_theme"

  Scenario: Should return error state when we have a non-wordpress based site
    Given I discover theme information for "whattheme.net"
    Then  I should see ":false"
    And   I should see "not_wordpress"
