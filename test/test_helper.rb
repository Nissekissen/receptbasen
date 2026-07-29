ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"
require_relative "test_helpers/session_test_helper"
require_relative "test_helpers/anthropic_test_helper"

# Real HTTP calls (page fetches, the Anthropic API) must be stubbed explicitly in
# each test — an unstubbed request raises instead of silently hitting the network.
WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    include AnthropicTestHelper

    # Add more helper methods to be used by all tests here...
  end
end
