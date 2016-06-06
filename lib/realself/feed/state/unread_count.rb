module RealSelf
  module Feed
    module State
      module UnreadCount

        ##
        # Retrieve the number of unread items for the current feed and owner
        #
        # @param [Objekt] The feed owner
        #
        # @return [Hash] {:owner_id => [owner.id], :count => 0}
        def get_unread_count(owner)
          result = state_collection(owner.type).find(
            {:owner_id => owner.id},
            {:fields => {:_id => 0}}
          ).limit(1)

          result.first ||  {:owner_id => owner.id, :count => 0}
        end

        ##
        # Decrement the unread count by 1 for the feed owner in the containing feed
        # Decrement will not cause the unread count to go below zero
        #
        # @param [Objekt] The user whose unread count is being changed
        def decrement_unread_count(owner)
          result = state_do_update(
            owner,
            {
            :owner_id => owner.id,
            :count => { :'$gt' => 0 }
          },
            {
            :'$inc' => { :count => -1 }
          })

          # if the update failed, assume the unread count is already at
          # zero, so return that.
          result ? result : {:owner_id => owner.id, :count => 0}
        end

        ##
        # Increment the unread count by 1 for the feed owner in the containing feed
        # up to MAX_FEED_SIZE if specified or 2147483647
        #
        # @param [Objekt] The user whose unread count is being changed
        def increment_unread_count(owner)
          result = state_do_update(
            owner,
            {
            :owner_id => owner.id,
            :count => { :'$lt' => self.class::MAX_FEED_SIZE }
          },
            {:'$inc' => {:count => 1}})

          # if the update failed, assume the unread count is already at
          # the max value so return that.
          result ? result : {:owner_id => owner.id, :count => self.class::MAX_FEED_SIZE}
        end

        ##
        # Resets the unread count to 0 for the feed owner in the containing feed
        #
        # @param [Objekt] The user whose unread count is being changed
        def reset_unread_count(owner)
          set_unread_count(owner, 0)
        end


        ##
        # Set the unread count to a specific value for the feed owner in the containig feed
        # Specifying values < 0 will cause the unread count to get set to 0.
        # Specifying values greater than MAX_FEED_SIZE will cause the unread count
        # to get set to MAX_FEED_SIZE
        #
        # @param [Objekt] The user whose unread count is being changed
        def set_unread_count(owner, count)
          result = unread_count_do_update(
            owner,
            {:owner_id => owner.id},
            {
            # keep the unread count between 0 and max feed size
            :'$set' => { :count => [[0, count].max, self.class::MAX_FEED_SIZE].min }
          })

          # if the update failed, assume the unread count is already at the passed value
          result ? result : {:owner_id => owner.id, :count => count}
        end
      end
    end
  end
end
