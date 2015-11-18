module RealSelf
  module Feed
    module Redactable

      attr_accessor :mongo_db


      ##
      # create indexes on the feed if necessary
      #
      # @param [String] owner_type  The type of object that owns the feed
      # @param [true | false]       Create the index in the background
      def ensure_index(owner_type, background: true)
        super if defined?(super)

        collection = get_collection(owner_type)

        collection.indexes.create_many([
          {
            :key        => {:'activity.redacted' => Mongo::Index::DESCENDING},
            :background => background,
            :sparse     => true
          }])
      end


      ##
      # marks all instances of an activity as redacted for all owners
      #
      # @param [String]   the UUID of the activity to redact
      #
      # @returns [int]  the number of feed owners for which this activity was redacted
      def redact(owner_type, activity_uuid)
        raise(
          RealSelf::Feed::FeedError,
          "Invalid UUID: #{activity_uuid}"
        ) unless activity_uuid.match(RealSelf::Stream::Activity::UUID_REGEX)

        collection = get_collection(owner_type)

        #update all documents that contain the activity
        result = collection.find({:'activity.uuid' => activity_uuid})
          .update_many(
            {:'$set' => {:redacted => true}},
            {:upsert => false, :multi => true})

        result.modified_count
      end


      ##
      # check for illegal composition
      def self.included(other)
        raise(
          FeedError,'Capped feeds may not include Redactable'
        ) if other.ancestors.include? RealSelf::Feed::Capped
      end
    end
  end
end
