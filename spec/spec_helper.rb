require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
end

require 'rubygems'
require 'rspec'

require 'pry-byebug'
require 'mongo'
require 'realself/stream'
require 'realself/handler'
require 'realself/feed'
require 'realself/daemon'
require 'realself/stream/digest/digest'

require_relative './realself/helpers'
require_relative './realself/stream/activity/activity_shared_examples'
require_relative './realself/stream/activity/followed_activity_shared_examples'
require_relative './realself/stream/digest/digest_spec'

