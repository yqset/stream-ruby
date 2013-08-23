require 'multi_json'

module RealSelf
  module Stream
    class Error
      def initialize(type, message)
        @type = type.to_s
        @message = message.to_s
      end

      def to_h
        {:type => @type, :message => @message}
      end

      alias :to_hash :to_h

      def to_s
        MultiJson::encode(to_h)
      end
    end
  end
end