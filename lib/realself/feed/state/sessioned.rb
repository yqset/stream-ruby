module RealSelf
  module Feed
    module State
      module Sessioned

        ##
        # Check if a user's session is still alive
        def is_session_alive?(owner)
          result = state_collection(owner.type).find(
            {:owner_id => owner.id},
            {:fields => {:_id => 0, :last_acted_time => 1}}
          ).limit(1)

          !result.nil? and !result.first.nil? and BSON::ObjectId.from_time(Time.now - self.class::SESSION_SECOND) < result.first[:last_acted_time]
        end

        def expire_session(owner)
          set_action_time(owner, time: BSON::ObjectId.from_time(Time.now - self.class::SESSION_SECOND))
        end

        def touch_session(owner)
          set_action_time(owner)
        end

        private
        
        def set_action_time(owner, time: BSON::ObjectId.from_time(Time.now))
          raise(
            FeedError,
            "Illegal time: #{time}. time must be a legal BSON::ObjectId"
          ) unless BSON::ObjectId.legal?(time)

          state_do_update(
            owner,
            {
            :owner_id => owner.id
          },
            {
            :'$set' => {:last_acted_time => time}
          })
        end
      end
    end
  end
end
