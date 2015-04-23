module RealSelf
  module Feed
    class Permanent
      include Getable

      attr_accessor :mongo_db

      ##
      # Insert a stream activity in to a permanent feed
      #
      # @param [ Objekt ] the owner of the feed
      # @param [ StreamActivity ] the stream activity to insert in to the feed
      def insert(owner, stream_activity)
        activity_hash = stream_activity.to_h

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

        unless @@mongo_indexes["#{collection.name}.owner_id"]
          collection.ensure_index({:'object.id' => Mongo::HASHED})
          collection.ensure_index({:'object.id' => Mongo::DESCENDING}, {:unique => true})
        end

        collection
      end
    end
  end
end
