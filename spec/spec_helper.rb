require 'simplecov'

SimpleCov.start

begin
  # activity objects
  require_relative '../lib/realself/stream'
  require_relative 'activity/stream_spec_helpers'
  require_relative 'activity/activity_shared_examples'
  require_relative 'activity/followed_activity_shared_examples'

  # digest objects
  require_relative '../lib/realself/stream/digest/digest'
  require_relative 'digest/digest_spec_helpers'
  require_relative 'digest/commentable_shared_examples'
  require_relative 'digest/summary_shared_examples'

  # coho objects
  require_relative 'coho/client_shared_examples'
rescue LoadError
  require 'rubygems'
  require 'rspec'
end
