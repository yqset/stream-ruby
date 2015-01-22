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
  require_relative './digest/digest_spec'
  require_relative './digest/commentable_summary_spec'

  # coho objects
  require_relative 'coho_shared_examples'
rescue LoadError
  require 'rubygems'
  require 'rspec'
end
