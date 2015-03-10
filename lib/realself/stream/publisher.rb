require 'bunny'

module RealSelf
  module Stream
    class Publisher
      def initialize(config, exchange_name)
        @publisher_session = Bunny.new(self.symbolize_keys(config))
        @publisher_session.start
        @publisher_channel = @publisher_session.create_channel
        @publisher_exchange = @publisher_channel.topic(exchange_name, :durable => true)
      end

      def publish(item, routing_key, content_type = 'application/json')
        @publisher_exchange.publish(
          item.to_s,
          :content_type => content_type.to_s,
          :persistent => true,
          :routing_key => routing_key.to_s
        )
      end

      private

      def self.symbolize_keys(hash)
        hash.inject({}){|result, (key, value)|
          new_key = case key
                    when String then key.to_sym
                    else key
                    end
          new_value = case value
                      when Hash then symbolize_keys(value)
                      else value
                      end
          result[new_key] = new_value
          result
        }
      end
    end
  end
end