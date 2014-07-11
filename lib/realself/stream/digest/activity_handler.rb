module RealSelf
  module Stream
    module Digest
      class ActivityHandler
        @@subclasses = {}

        def self.create(type, debug_mode, logger)
          klass = @@subclasses[type]
          if( klass )
            klass.new(debug_mode, logger)
          else
            raise "unknown activity type: #{type}"
          end
        end

        def self.register_handler(type)
          @@subclasses[type] = self
        end

        def initialize(debug_mode, logger)
          @debug_mode = debug_mode
          @logger = logger
        end

      end
    end
  end
end

Dir[File.dirname(__FILE__) + '/activity/*.rb'].each {|file| require file }
