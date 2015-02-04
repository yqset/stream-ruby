module RealSelf
  module Stream
    class ActivityHandlerFactory

      @@registered_handlers = {}

      def self.create(activity_prototype, content_type)
        klass = @@registered_handlers[content_type] ? @@registered_handlers[content_type][activity_prototype.to_s] : nil

        if( klass )
          handler = klass.new
          yield handler if block_given?
          # TODO: if/when we want to initialize handlers
          # with default parameters, do it here before
          # returning the new instance
          # see http://joshrendek.com/2013/11/2-patterns-for-refactoring-with-your-ruby-application/
          handler
        else
          raise "no handler registered for content type:activity prototype - #{content_type}:#{activity_prototype}"
        end
      end


      def self.register_handler(activity_prototype, content_type, klass)
        @@registered_handlers[content_type] = @@registered_handlers[content_type] || {}
        @@registered_handlers[content_type][activity_prototype.to_s] = klass
      end


      def self.registered_handlers()
        handler_names = []
        @@registered_handlers.each do | content_type, handlers |
          handlers.each_key{|key| handler_names << "#{content_type}::#{key}"}
        end

        handler_names
      end

    end

    class ActivityHandlerFactoryError < StandardError
    end
  end
end