$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
RSPEC_ROOT = File.dirname(__FILE__)
GEM_ROOT = File.expand_path("..", RSPEC_ROOT)

require 'simplecov'
SimpleCov.root GEM_ROOT
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/.bundle/"
end

require 'rspec'
require 'webmock/rspec'
require 'hubspot-api-legacy'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{RSPEC_ROOT}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :rr

  config.after(:each) do
    HubspotLegacy::Config.reset!
  end

  config.extend CassetteHelper
  config.extend TestsHelper
end
