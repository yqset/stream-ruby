require 'mongo'
require 'simplecov'

module IntegrationHelper
  include Mongo

  def self.get_mongo
    @db_name        ||= "integration_test_#{Time.now.to_i}"
    @mongo_client   ||= Mongo::Client.new 'mongodb://localhost:27017'
    @mongo_db       ||= Mongo::Database.new @mongo_client, @db_name
    @mongo_db
  end

  def self.destroy_mongo
    @mongo_db.drop
  end

  class << self
    attr_accessor :skip_ttl_test
  end
end

RSpec.configure do |config|
  config.before :all do
    ::IntegrationHelper.get_mongo

    ::IntegrationHelper.skip_ttl_test = true if ENV['SKIP_TTL_TESTS']

  end

  config.after :all do
    ::IntegrationHelper.destroy_mongo
  end
end

SimpleCov.command_name "test:integration"
