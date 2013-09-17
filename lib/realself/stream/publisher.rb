require 'bunny'

module RealSelf
  module Stream
    class Publisher
      class << self
        def configure(config, exchange_name)
          @@publisher_session = Bunny.new(symbolize_keys(config))
          @@publisher_session.start
          @@publisher_channel = @@publisher_session.create_channel
          @@publisher_exchange = @@publisher_channel.topic(exchange_name, :durable => true)
        end

        def publish(item)
          @@publisher_exchange = @@publisher_exchange || self.initialize_publisher

          @@publisher_exchange.publish(
            item.to_s,
            :content_type => 'application/json',
            :persistent => true,
            :routing_key => "#{item.actor.type}.#{item.verb}.#{item.object.type}"
          )
        end

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
end