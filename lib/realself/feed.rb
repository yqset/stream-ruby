module RealSelf
  module Feed
  end
end

Dir[File.dirname(__FILE__) + '/feed/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/feed/state/*.rb'].each {|file| require file }
require 'realself/logger'
require 'realself/stream/activity'
