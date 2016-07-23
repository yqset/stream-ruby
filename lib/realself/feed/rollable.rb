require 'set'

module RealSelf
  module Feed
    module Rollable

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
            :key        => {:'activity.prototype' => Mongo::Index::DESCENDING},
            :background => background
          },
          {
            :key        => {:'activity.actor' => Mongo::Index::DESCENDING},
            :background => background
          },
          {
            :key        => {:'activity.object' => Mongo::Index::DESCENDING},
            :background => background
          }
        ])
      end

      ##
      # Insert a stream activity in to a feed while rolling up if possible
      #
      # @param [ Objekt ] the owner of the feed
      # @param [ StreamActivity ] the stream activity to insert in to the feed
      # @param [ Hash ] query     a hash containing a mongo query to use as match criteria for roll up
      # @param [ Array ] keys   an array containing hash keys in sequence to the rolling object
      def insert_or_rollup(owner, stream_activity, query, keys)
        raise(
          RealSelf::Feed::FeedError,
          "Invalid keys: #{keys}. keys must be an Array and can't be empty"
        ) unless keys.is_a?(Array) && !keys.empty?

        activity_hash = stream_activity.to_h
        collection = get_collection(owner.type)

        #match on object and prototype
        #remove and get item
        match_criteria = get_roll_match_criteria(owner, stream_activity, query)
        orig_sa = collection.find_one_and_delete(match_criteria)
        unless orig_sa.nil?
          rolled_up_set = Set.new(orig_sa['roll_up'])
          rolled_up_set.add(get_roll_object(orig_sa['activity'], keys))

          activity_hash[:roll_up] = rolled_up_set.to_a
        end

        upsert_query = {
          :'activity.uuid'  => stream_activity.activity.uuid,
          :'object.id'      => owner.id
        }
        collection.find(upsert_query)
          .update_one(activity_hash, :upsert => true)
      end


      def self.included(other)
        raise(
          FeedError,'Capped feeds do not support Rollable'
        ) if other.ancestors.include? RealSelf::Feed::Capped
      end

      private

      def get_roll_match_criteria(owner, stream_activity, query)
        {
          :'object.id'          => owner.id,
          :'activity.prototype' => stream_activity.activity.prototype
        }.merge(query)
      end

      def get_roll_object(activity, keys)
        begin
          object = activity
          keys.each { |k|
            object = object[k]
          }
          object
        rescue NoMethodError
          raise(FeedError, "Invalid keys: #{keys}")
        end
      end
    end
  end
end
