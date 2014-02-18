module RealSelf
  module Stream
    class RoutingKey

      def initialize(activity)
        @activity = activity
      end

      def to_s
        activity.prototype
      end

    end
  end
end
