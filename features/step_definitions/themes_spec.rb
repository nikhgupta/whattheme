require 'cgi'

Given /^I am on (.*)$/ do |page|
  visit path_to(page)
end

Then /^I should see "([^"]*)"$/ do |text|
  page.should have_content text
end

Then /^the page should be in "([^"]*)" format$/ do |format|
  page.response_headers['Content-Type'].should have_content format
end

When /^I discover theme information for "([^"]*)"$/ do |url|
  visit discover_path(:url => CGI::escape(url))
end

Then /^the cms discovered should be "([^"]*)"$/ do |cms|
  page.should have_content "\"cms\":\"#{cms}\""
end

Then /^the theme discovered should be "([^"]*)"$/ do |theme|
  page.should have_content "\"theme_name\":\"#{theme}\""
end
