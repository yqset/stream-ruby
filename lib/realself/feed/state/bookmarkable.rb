module RealSelf
  module Feed
    module State
      module Bookmarkable
        ##
        # Terminology
        # "position"        => A marker that indicates where a particular users were on their feed
        ##

        ##
        # Retrieve the position of a user
        #
        # @return BSON::ObjectId | nil
        def get_bookmark(owner)
          result = state_collection(owner.type).find(
            {:owner_id => owner.id},
            {:fields => {:_id => 0, :position => 1}}
          ).limit(1)

          result.first[:position]
        end

        ##
        # Set the position of a user
        def set_bookmark(owner, position)
          raise(
            FeedError,
            "Illegal position: #{position}. Position must be a legal BSON::ObjectId"
          ) unless position.is_a?(BSON::ObjectId) and BSON::ObjectId.legal?(position)

          result = state_do_update(
            owner,
            {
            :owner_id => owner.id
          },
            {
            :'$set' => {:position => position}
          })

          position if result
        end

        ##
        # Forget a position of a user
        def forget_bookmark(owner)
          state_do_update(owner, {:owner_id => owner.id}, {:'$unset' => {:position => ""}})
        end
      end
    end
  end
end
