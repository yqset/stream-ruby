require 'bunny'

module RealSelf
  module Stream
    class Publisher
      class << self
        def configure(config, exchange_name)
          @@publisher_session = Bunny.new(config)
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
      end
    end
  end
end