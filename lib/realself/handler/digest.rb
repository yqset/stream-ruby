module RealSelf
  module Handler
    module Digest

      module ClassMethods
        def register_handler(activity_prototype)
          RealSelf::Handler::Factory.register_handler(
            activity_prototype,
            RealSelf::ContentType::DIGEST_ACTIVITY,
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
