module RealSelf
  module Handler
    module StreamActivity

      module ClassMethods
        def register_handler(activity_prototype)
          RealSelf::Handler::Factory.register_handler(
            activity_prototype,
            RealSelf::ContentType::STREAM_ACTIVITY,
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
