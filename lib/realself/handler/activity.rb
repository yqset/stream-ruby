module RealSelf
  module Handler
    module Activity

      module ClassMethods
        def register_handler(activity_prototype)
          RealSelf::Handler::Factory.register_handler(
            activity_prototype,
            RealSelf::Stream::ContentType::ACTIVITY,
            self
          )
        end
      end

      def self.included(other)
        other.extend ClassMethods
      end

    end
  end
end
