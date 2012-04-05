Given /^PENDING/ do
  pending
end

Given /^I am on (.*)$/ do |page|
  visit path_to(page)
end

Then /^I should see "([^"]*)"$/ do |text|
  page.should have_content text
end

Then /^the page should be in "([^"]*)" format$/ do |format|
  page.response_headers['Content-Type'].should have_content format
end

Given /^I discover theme information for "([^"]*)"$/ do |url|
  visit discover_path(:url => url)
end
