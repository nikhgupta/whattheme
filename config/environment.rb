# Load the rails application
require File.expand_path('../application', __FILE__)

# this allows WEBrick to handle pipe symbols in query parameters
URI::DEFAULT_PARSER = URI::Parser.new(:UNRESERVED => URI::REGEXP::PATTERN::UNRESERVED + '|')

# Initialize the rails application
Api::Application.initialize!
