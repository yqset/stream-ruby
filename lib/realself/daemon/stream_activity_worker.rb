module RealSelf
  module Daemon
    class StreamActivityWorker
      include Sneakers::Worker
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation if CONFIG[:newrelic_agent]

      # default handler constructor parameters
      class << self
        attr_accessor :handler_params
      end


      # sneakers queue configuration
      from_queue CONFIG[:stream_activity_queue],
                 :ack         => true,
                 :durable     => true,
                 :exchange    => CONFIG[:stream_activity_exchange],
                 :prefetch    => 1,
                 :routing_key => Handler::Factory.registered_routing_keys(ContentType::STREAM_ACTIVITY),
                 :threads     => 1


      def work_with_params message, delivery_info, metadata
        stream_activity = Stream::Factory.from_json ContentType::STREAM_ACTIVITY, message
        enclosure       = Handler::Factory.enclosure CONFIG[:stream_activity_queue]
        handlers        = Handler::Factory.create(
                            stream_activity.prototype,
                            stream_activity.content_type,
                            self.class.handler_params)

        enclosure.handle do
          handlers.each { |h| h.handle stream_activity }
        end
      end


      add_transaction_tracer :work_with_params, name: 'MetricsWorker', params: 'args[0]' if CONFIG[:newrelic_agent]
    end
  end
end
