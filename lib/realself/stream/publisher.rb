require 'bunny'

module RealSelf
  module Stream
    class Publisher
      def initialize(config, exchange_name, opts = {})
        @exchange_name    = exchange_name
        @exchange_options = opts # see: https://github.com/ruby-amqp/bunny/blob/master/lib/bunny/exchange.rb#L56-L86
        session           = Bunny.new(symbolize_keys(config))

        session.start

        @channel  = session.create_channel
      end

      def publish(item, routing_key, content_type = 'application/json')
        @channel.open unless @channel.open?

        exchange = @channel.topic(@exchange_name, @exchange_options)

        exchange.publish(
          item.to_s,
          :content_type => content_type.to_s,
          :persistent => true,
          :routing_key => routing_key.to_s
        )

        @channel.close
      end

      private

      def symbolize_keys(hash)
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
