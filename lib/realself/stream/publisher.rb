require 'bunny'

module RealSelf
  module Stream

    class PublisherError < StandardError; end

    class Publisher
      MAX_CONNECTION_RETRY = 3

      def initialize(config, exchange_name)
        @exchange_name  = exchange_name
        @rmq_config     = config

        # generally speaking, threading with publishing is not safe
        # just don't do it.
        @rmq_config[:threaded] = false

        initialize_connection
        open_channel
      end


      def confirm_publish_end
        # this will block until RMQ responds
        @publisher_channel.wait_for_confirms

        # nacked_set returns Set containg the hash code of
        # any messages that failed to publish. Go find
        # the original item based on the hash code and
        # log it as an error.
        nacks = @publisher_channel.nacked_set

        @publisher_channel.close if @publisher_channel.open?

        nacks.each do |nack|
          failed_item = @batch.find { |item| item.hash == nack }
          RealSelf::logger.error("Failed to confirm publish for item.  activity=#{failed_item.to_s}")
        end

        unless nacks.empty?
          raise PublisherError, "Failed to confirm #{nacks.count} published items."
        end

        @batch = nil
      end


      def confirm_publish_start items
        @batch = [*items]

        @publisher_channel.close if @publisher_channel and @publisher_channel.open?

        open_channel

        # enable publish confirmation
        @publisher_channel.confirm_select
      end


      def publish(item, routing_key, content_type = 'application/json')
        tries ||= 1

        open_channel unless @publisher_channel and @publisher_channel.open?

        @publisher_exchange.publish(
          item.to_s,
          :content_type => content_type.to_s,
          :message_id   => item.hash,
          :persistent   => true,
          :routing_key  => routing_key.to_s)

      rescue ::Bunny::NetworkFailure, ::Bunny::NetworkErrorWrapper => nfe

        if tries <= MAX_CONNECTION_RETRY

          RealSelf::logger.warn "#{nfe.class.name} error detected.  Attempting reconnection #{tries}/#{MAX_CONNECTION_RETRY}"

          @publisher_channel.maybe_kill_consumer_work_pool!

          sleep tries # wait a little longer between each attempt

          initialize_connection

          if @batch
            RealSelf::logger.warn "Network error during confirmed batch publish.  Some messages were not confirmed.  Resuming batch."
            confirm_publish_start @batch
          end

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
      end


      def open_channel
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
