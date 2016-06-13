require 'bunny'

module RealSelf
  module Stream
    class Publisher
      MAX_CONNECTION_RETRY = 3

      def initialize(config, exchange_name)
        @exchange_name  = exchange_name
        @rmq_config     = config

        # default to single threded connections for publishing
        # unless explicitly specified otherwise
        @rmq_config[:threaded] = false unless config[:threaded]

        initialize_connection
      end

      def publish(item, routing_key, content_type = 'application/json')
        tries ||= 1

        @publisher_exchange.publish(
          item.to_s,
          :content_type => content_type.to_s,
          :persistent => true,
          :routing_key => routing_key.to_s)

      rescue ::Bunny::NetworkFailure, ::Bunny::NetworkErrorWrapper => nfe

        if tries <= MAX_CONNECTION_RETRY

          RealSelf::logger.warn "#{nfe.class.name} error detected.  Attempting reconnection #{tries}/#{MAX_CONNECTION_RETRY}"

          @publisher_channel.maybe_kill_consumer_work_pool!

          sleep tries # wait a little longer between each attempt

          initialize_connection

          tries += 1

          retry
        else

          RealSelf::logger.error "#{nfe.class.name} detected.  Exhausted #{MAX_CONNECTION_RETRY} attempts.\n#{nfe.message}\n#{nfe.backtrace}"
          raise nfe
        end
      end


      private


      def initialize_connection
        @publisher_session  = Bunny.new(symbolize_keys(@rmq_config))
        @publisher_session.start

        @publisher_channel  = @publisher_session.create_channel
        @publisher_exchange = @publisher_channel.topic(@exchange_name, :durable => true)
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
