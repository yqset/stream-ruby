module Realself
  module Stream
    class RoutingKey

      def initialize(activity)
        @activity = activity
      end

      def to_s
        "#{@activity.actor.type}.#{@activity.verb}.#{@activity.object.type}"
      end

    end
  end
end
