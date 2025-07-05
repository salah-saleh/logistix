ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Disable test parallelization for Mongoid to avoid test pollution and missing data issues.
    # See: https://guides.rubyonrails.org/testing.html#running-tests-in-parallel
    # Mongoid does not support parallel test DBs out of the box.
    # parallelize(workers: :number_of_processors)
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
