# Load the Rails application.
puts "Loading the Rails application"
puts ENV.inspect
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!
