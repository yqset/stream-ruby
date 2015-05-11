module RealSelf
  module Handler
    module Enclosure

      ##
      # default (no-op) wrapper method
      # this enclosure will be used if no other is specified
      def self.handle
        yield

        :ack
      end
    end
  end
end
