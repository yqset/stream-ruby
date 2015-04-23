require 'simplecov'

SimpleCov.start

begin

  # activity objects
  require 'realself/feed'
  require 'realself/handler'
  require 'realself/stream'
  require 'realself/stream/digest/digest'
  require 'mongo'

  # activity tests
  require_relative 'activity/helpers'

  require_relative './stream/activity/activity_shared_examples'
  require_relative './stream/activity/followed_activity_shared_examples'

  require_relative './stream/digest/digest_spec'
  require_relative './stream/digest/commentable_summary_spec'

  # coho objects
  require_relative './stream/coho_shared_examples'
rescue LoadError
  require 'rubygems'
  require 'rspec'
end
