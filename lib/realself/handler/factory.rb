module RealSelf
  module Handler
    class Factory

      @@registered_handlers = {}

      def self.create(activity_prototype, content_type)
        klasses = @@registered_handlers[content_type] ? @@registered_handlers[content_type][activity_prototype.to_s] : []

        raise(
          HandlerFactoryError,
          "no handler registered for content type:activity prototype - #{content_type}:#{activity_prototype}"
        )if klasses.nil?

        klasses.values.map do |klass|
          handler = klass.new
          yield handler if block_given?
          # TODO: if/when we want to initialize handlers
          # with default parameters, do it here before
          # returning the new instance
          # see http://joshrendek.com/2013/11/2-patterns-for-refactoring-with-your-ruby-application/
          handler
        end
      end


      def self.register_handler(activity_prototype, content_type, klass)
        @@registered_handlers[content_type] ||= {}
        @@registered_handlers[content_type][activity_prototype.to_s] ||= {}
        @@registered_handlers[content_type][activity_prototype.to_s][klass.name] = klass
      end


      def self.registered_handlers()
        names = []
        @@registered_handlers.each do |content_type, prototype_handlers|
          prototype_handlers.each do |prototype, handlers|
            handlers.keys.each do |class_name|
              names << "#{content_type} => #{prototype} => #{class_name}"
            end
          end
        end
        names
      end
    end


    class HandlerFactoryError < StandardError
    end
  end
end
