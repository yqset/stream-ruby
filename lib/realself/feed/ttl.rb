module RealSelf
  module Feed
    class Ttl
      include Getable

      attr_accessor :mongo_db

      ##
      # Insert a stream activity in to a ttl feed
      #
      # @param [ Objekt ] the owner of the feed
      # @param [ StreamActivity ] the stream activity to insert in to the feed
      def insert(owner, stream_activity)
        activity_hash = stream_activity.to_h
        activity_hash[:created] = Time.now.utc

        upsert_query = {
          :'activity.uuid'  => stream_activity.activity.uuid,
          :'object.id'      => owner.id
        }

        collection(owner).update(
          upsert_query,
          activity_hash,
          {:upsert => true}
        )
      end


      private

      @@mongo_indexes ||= {}


      ##
      # get the collection for this feed
      # and ensure the required indexes
      def collection(owner)
        collection = @mongo_db.collection("#{owner.type}.#{self.class::FEED_NAME}")

        # After consultation with Matt T, this check is largely unnecessary, and it
        # actually makes changing TTLs difficult.  With this check in place, the
        # daemon handler and rest service for ALL feeds must be shut down in order
        # to change the TTL on a single feed.
        #
        # unless @@mongo_indexes["#{collection.name}.owner_id"]
        #   # make sure the TTL has not changed since the feed was created
        #   collection.index_information.each_value do |index|
        #     if index['key']['created'] and index['expireAfterSeconds'] != self.class::FEED_TTL_SECONDS
        #       raise FeedError, 'Cannot change expiration on existing TTL collection'
        #     end
        #   end

        #   # used for insert/update
        #   collection.ensure_index(
        #     {
        #       :'activity.uuid'  => Mongo::DESCENDING,
        #       :'object.id'      => Mongo::DESCENDING
        #     })

        #   # used for read
        #   collection.ensure_index(
        #     {
        #       :'object.id'  => Mongo::DESCENDING,
        #       :_id          => Mongo::DESCENDING
        #     })

        #   # TTL expiration time
        #   collection.ensure_index(
        #     {:created => Mongo::ASCENDING},
        #     {:expireAfterSeconds => self.class::FEED_TTL_SECONDS})

        #   @@mongo_indexes["#{collection.name}.owner_id"] = true
        # end

        collection
      end
    end
  end
end
