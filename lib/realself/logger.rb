module RealSelf
  extend self

  attr_accessor :logger

  @logger = Logger.new(STDOUT)
end
