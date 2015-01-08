module RealSelf
  module Stream
    class ActivityHandler

      @@registered_handlers = {}

      def self.create(activity_prototype)
        klass = @@registered_handlers[activity_prototype.to_s]

        if( klass )
          handler = klass.new
          yield handler if block_given?
          # TODO: if/when we want to initialize handlers
          # with default parameters, do it here before
          # returning the new instance
          # see http://joshrendek.com/2013/11/2-patterns-for-refactoring-with-your-ruby-application/
          handler
        else
          raise "no handler registered for activity prototype:#{activity_prototype}"
        end
      end

      def self.register_handler(activity_prototype)
        @@registered_handlers[activity_prototype.to_s] = self
      end

      def self.registered_handlers()
        @@registered_handlers.keys
      end

    end
  end
end