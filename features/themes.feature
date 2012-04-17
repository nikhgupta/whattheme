Feature: What Theme
  In order to provide information about a theme
  As a developer
  I need to provide an api for requesting information about themes

  #@pending
  #Scenario: API Home should list Documentation for API
    #Given PENDING I am on the home page
    #Then  I should see "Documentation"

  @output
  Scenario: JSON should be the default format
    Given I am on the themes page
    Then  the page should be in "json" format

  @detect @cms @unknown
  Scenario: Should display a clear message when the site does not use a CMS
    When I discover theme information for "whattheme.net"
    Then the cms discovered should be "unknown"
    And  I should see "low key CMS"
    And  I should see "not using a CMS at all"

  @detect @cms @joomla
  Scenario: Detect Joomla
    When I discover theme information for "joomla.org"
    Then the cms discovered should be "Joomla"

  @detect @cms @drupal
  Scenario: Detect Drupal
    When I discover theme information for "drupal.org"
    Then the cms discovered should be "Drupal"

  @detect @cms @wordpress
  Scenario: Detect WordPress
    When I discover theme information for "wordpress.org"
    Then the cms discovered should be "WordPress"
    When I discover theme information for "nikhgupta.com"
    Then the cms discovered should be "WordPress"

  @detect @theme @wordpress @real
  Scenario: Should return theme information using Stylesheets
    When I discover theme information for "nikhgupta.com"
    Then the theme discovered should be "1 Quattro"

  @detect @theme @wordpress @real @inner
  Scenario: Should return theme information for inner pages
    When I discover theme information for "http://www.prelovac.com/vladimir/"
    Then the theme discovered should be "Imbue"
    When I discover theme information for "http://nikhgupta.com/photography/the-green-leaves/"
    Then the theme discovered should be "1 Quattro"

  @detect @theme @wordpress @guess
  Scenario: Should return theme information using Introspection
    When I discover theme information for "wordpress.com"
    Then the theme discovered should be "h4"

  @detect @theme @wordpress @unknown
  Scenario: Should display a fair message when a theme can not be discovered
    When I discover theme information for "wordpress.org"
    Then I should see "customized WordPress theme"
