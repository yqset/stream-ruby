module RealSelf
  module Stream
    module Daemon
      class ActivityHandler

        @@registered_handlers = {}

        def self.create(routing_key, content_type)
          handler_type = "#{routing_key}::#{content_type}"
          klass = @@registered_handlers[handler_type]

          if( klass )
            handler = klass.new
            yield handler if block_given?
            # TODO: if/when we want to initialize handlers
            # with default parameters, do it here before
            # returning the new instance
            # see http://joshrendek.com/2013/11/2-patterns-for-refactoring-with-your-ruby-application/
            handler
          else
            raise "no handler registered for routing key:#{routing_key} and content-type:#{content_type}"
          end
        end

        def self.register_handler(routing_key, content_type)
          handler_type = "#{routing_key}::#{content_type}"
          @@registered_handlers[handler_type] = self
        end

        def self.registered_handlers()
          @@registered_handlers.keys
        end

      end
    end
  end
end