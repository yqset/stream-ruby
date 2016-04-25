require 'rubygems'
require 'rspec'
require 'simplecov'

require 'pry-byebug'
require 'mongo'
require 'realself/stream'
require 'realself/handler'
require 'realself/feed'
require 'realself/graph/follow'
require 'realself/daemon'
require 'realself/stream/digest/digest'

require_relative './helpers'
require_relative './integration/integration_helper' unless ARGV[0] && ARGV[0].match(/spec\/unit/)
require_relative './integration/realself/feed/getable_shared_examples'
require_relative './integration/realself/feed/insertable_shared_examples'
require_relative './integration/realself/feed/redactable_shared_examples'
require_relative './integration/realself/feed/unread_countable_shared_examples'
require_relative './unit/realself/stream/digest/digest_spec'

SimpleCov.start do
  add_filter '/spec/'
end
