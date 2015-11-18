module RealSelf
  module Feed
    class Ttl
      include Getable

      attr_accessor :mongo_db


      ##
      # create indexes on the feed if necessary
      #
      # @param [String] owner_type  The type of object that owns the feed
      # @param [true | false]       Create the index in the background
      # @param [mongo_db] mongo     The mongo db client instance
      def self.ensure_index(owner_type, background: true, mongo:)
        super if defined?(super)

        collection = mongo.collection("#{owner_type}.#{self::FEED_NAME}") 
   
        collection.indexes.create_many([
          {
            :key => {
              :'object.id'  => Mongo::Index::DESCENDING,
              :_id          => Mongo::Index::DESCENDING
            },
            :background => background,
            :unique     => true
          },
          {
            :key => {
              :'activity.uuid'  => Mongo::Index::DESCENDING,
              :'object.id'      => Mongo::Index::DESCENDING
            },
            :background => background,
            :unique     => true
          },
          {
            :key          => {:created => Mongo::Index::ASCENDING},
            :background   => background,
            :expire_after => self::FEED_TTL_SECONDS
          }
        ])
      end


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

        get_collection(owner.type).find(upsert_query)
          .update_one(activity_hash,:upsert => true)
      end


      private


      ##
      # get the collection for this feed
      # and ensure the required indexes
      def get_collection(owner_type)
        @mongo_db.collection("#{owner_type}.#{self.class::FEED_NAME}")
      end
    end
  end
end
