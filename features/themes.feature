Feature: What Theme
  In order to provide information about a theme
  As a developer
  I need to provide an api for requesting information about themes

  @pending
  Scenario: API Home should list Documentation for API
    Given I am on the home page
    Then  I should see "Documentation"

  Scenario: JSON should be the default format
    Given I am on the themes page
    Then  the page should be in "json" format

  Scenario: JSON and XML should be the only formats allowed
