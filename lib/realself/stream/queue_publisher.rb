require 'bunny'
require 'realself/stream/queue_item'

module RealSelf
  module Stream
    class QueuePublisher
      class << self
        def configure(config = nil, exchange_name = 'realself.activities')
          @@publisher_session = Bunny.new(config)
          @@publisher_session.start
          @@publisher_channel = @@publisher_session.create_channel
          @@publisher_exchange = @@publisher_channel.topic(exchange_name, :durable => true)
        end

        def publish(queue_item)
          @@publisher_exchange = @@publisher_exchange || self.initialize_publisher

          @@publisher_exchange.publish(
            queue_item.to_s,
            :content_type => 'appliaction/json',
            :persistent => true,
            :routing_key => "#{queue_item.actor.type}.#{queue_item.verb}.#{queue_item.object.type}"
          )
        end
      end
    end
  end
end