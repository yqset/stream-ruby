module RealSelf
  module Feed
    module State
      module Timer
        ##
        # Terminology
        # "last_acted_time" => Time that specifies last action(view content, read feed, etc) of a user.
        ##

        ##
        # Check if a user's session is still alive
        def is_session_alive?(owner)
          result = state_collection(owner.type).find(
            {:owner_id => owner.id},
            {:fields => {:_id => 0, :last_acted_time => 1}}
          ).limit(1)

          !result.nil? and !result["last_acted_time"].nil? and Time.now - result["last_acted_time"].getTime() < self.class::SESSION_SECOND
        end

        def set_action_time(owner, time: DateTime.now)
          result = state_do_update(
            owner,
            {
              :owner_id => owner.id
            },
            {
              :'$set' => {:last_acted_time => time}
            })
      
            result
        end

      end
    end
  end
end
