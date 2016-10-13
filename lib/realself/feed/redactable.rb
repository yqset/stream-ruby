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
      # marks all instances of activities that belongs to this owner that satisfies the query
      #
      # @param [RealSelf::Stream::Objekt]  owner object
      # @param [Hash]                      mongo query
      #
      # @return [int]  the number of activities redacted
      def redact_by_query(owner, query)
        collection = get_collection(owner.type)
        feed_query = query.merge({:'object.id' => owner.id})

        result = collection.find(feed_query)
          .update_many(
            {:'$set' => {:redacted => true}},
            {:upsert => false, :multi => true})

        result.modified_count
      end

      ##
      # marks all instances of an activity as redacted for all owners
      #
      # @param [Hash]   query criteria hash of activities to redact
      #
      # @returns [int]  the number of feed owners for which this activity was redacted
      def redact_by_activity(owner_type, query)
        raise(
          RealSelf::Feed::FeedError,
          "Invalid activity query: #{query}"
        ) unless query.is_a?(Hash) && !query.empty?

        collection = get_collection(owner_type)
        feed_query = {:redacted => {:'$ne' => true}}.merge(query) #omit redacted items
        raise(
          RealSelf::Feed::FeedError,
          "Provided query returns more than 1 unique uuid to redact."
        ) unless collection.distinct(:'activity.uuid', feed_query).size <= 1

        #update all documents that matches the criteria
        result = collection.find(feed_query).limit(1).to_a

        uuid = result[0]['activity']['uuid'] unless result.empty?

        uuid ? redact(owner_type: owner_type, {:'activity.uuid' => uuid}) : 0
      end


      ##
      # marks all instances of an activity as redacted for all owners
      #
      # @param [String]   the UUID of the activity to redact
      #
      # @returns [int]  the number of feed owners for which this activity was redacted
      def redact(owner_type: 'user', query: nil)
        collection = get_collection(owner_type)

        #update all documents that contain the activity
        result = collection.find(query)
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
