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
        def get_position(owner)
          result = state_collection(owner.type).find(
            {:owner_id => owner.id},
            {:fields => {:_id => 0, :position => 1}}
          ).limit(1)

          result.first || {:owner_id => owner.id, :position => BSON::ObjectId.from_string("000000000000000")}
        end

        ##
        # Set the position of a user
        def set_position(owner, position)
          raise(
            FeedError,
            "Illegal position: #{position}. Position must be a legal BSON::ObjectId"
          ) unless BSON::ObjectId.legal?(position)

          result = state_do_update(
            owner,
            {
            :owner_id => owner.id
          },
            {
            :'$set' => {:position => position}
          })

          result
        end
      end
    end
  end
end
