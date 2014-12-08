module RealSelf
  module Stream
    module Digest
      module Summary
        class UserMessage < AbstractSummary
          def initialize(object)
            super
            hash = {
              :user_message => {:count => 0}
            }
            @activities.merge!(hash)
          end

          def add(stream_activity)
            activity = stream_activity.activity
            case activity.prototype
            when 'user.send.user_message'
              @activities[:user_message][:count] += 1
              @activities[:user_message][:last] = activity.object.to_h
            else
              super
            end

            @empty = false
          end
        end
      end
    end
  end
end