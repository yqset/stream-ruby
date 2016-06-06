module RealSelf
  module Feed
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

        result.first || {:owner_id => owner.id, :position => nil}
      end

      ##
      # Set the position of a user
      def set_position(owner, position)
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

      def self.included(other)
        other.class_eval do
          puts "Including Stateful from bookmarkble"
          include Stateful
        end unless other.ancestors.include? RealSelf::Feed::Stateful
      end
    end
  end
end
