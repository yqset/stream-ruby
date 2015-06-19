module RealSelf
  module Stream
    module Digest
      module Summary
        class User
          include Summarizable

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
              # note that we do NOT call 'super' here
              # the only activity type that we currently digest
              # on user objects is user.send.user_message, but
              # it is legal for a stream_activity 'reasons' list to
              # include user objects because all objects implicitly follow
              # themselves - see FollowedActivity::map_followers()
              # therefore, when any activity is issued that contains a
              # user object, a corresponding stream_activity will be issued
              # with that user as the owner and a corresponding user summary
              # will be created.  See Digest::add()
              #
              # In all of these cases, we want to silently fail and continue
              # unless or until we specifically start supporting summarizing
              # other types of user activity in digests.
              #
              # A side effect of this is that unlike other digest types,
              # User will not throw an exception when unknown activity types
              # are encountered.
              return
            end

            @empty = false
          end

          Digest.register_summary_type(:user, self)
        end
      end
    end
  end
end
