module RealSelf
  module Daemon
    module Worker

      # default worker options
      WORKER_OPTIONS = {
         :ack         => true,
         :durable     => true,
         :prefetch    => 1,
         :threads     => 1
      }


      def work_with_params message, delivery_info, metadata
        stream_activity = Stream::Factory.from_json self.class.content_type, message
        enclosure       = Handler::Factory.enclosure self.class.queue_name
        handlers        = Handler::Factory.create(
                            stream_activity.prototype,
                            stream_activity.content_type,
                            self.class.handler_params)

        enclosure.handle do
          handlers.each { |h| h.handle stream_activity }
        end
      end


      module ClassMethods
        attr_accessor :content_type, :worker_options
        attr_reader   :configured, :handler_params

        def configure(exchange_name:, queue_name:, handler_params: {}, enable_newrelic: false, enable_dlx: false, worker_options: WORKER_OPTIONS)
          @handler_params = handler_params

          worker_options[:exchange]    = exchange_name
          worker_options[:routing_key] = Handler::Factory.registered_routing_keys(self.content_type)

          # enable DLX with default name if requested
          worker_options.merge!(
            :arguments   => {:'x-dead-letter-exchange' => "dlx.#{queue_name}"}
          ) if enable_dlx

          @worker_options = worker_options

          # sneakers queue configuration
          from_queue queue_name, worker_options

          if enable_newrelic
            include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
            add_transaction_tracer :work_with_params, name: 'MetricsWorker', params: 'args[0]'
          end

          @configured = true
        end
      end

      def self.included(other)
        other.extend ClassMethods
      end
    end
  end
end
