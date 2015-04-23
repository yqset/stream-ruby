module RealSelf
  module Feed
    module UnreadCountable

      attr_accessor :mongo_db

      MAX_UNREAD_COUNT = 2147483647.freeze
      MONGO_ERROR_DUPLICATE_KEY = 11000.freeze

      ##
      # Decrement the unread count by 1 for the feed owner in the containing feed
      # Decrement will not cause the unread count to go below zero
      #
      # @param [Objekt] The user whose unread count is being changed
      def decrement_unread_count(owner)
        unread_count_do_update(
          owner,
          {
            :query => {
              :owner_id => owner.id,
              :count => { :'$gt' => 0 }
            },
            :update => {
              :'$inc' => { :count => -1}
            },
            :upsert => true
          }
        )
      end


      ##
      # Increment the unread count by 1 for the feed owner in the containing feed
      # up to MAX_FEED_SIZE if specified or 2147483647
      #
      # @param [Objekt] The user whose unread count is being changed
      def increment_unread_count(owner)
        unread_count_do_update(
          owner,
          {
            :query => {
              :owner_id => owner.id,
              :count => { :'$lt' => self.class::MAX_FEED_SIZE }
            },
            :update => {
              :'$inc' => { :count => 1}
            },
            :upsert => true
          }
        )
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
        unread_count_do_update(
          owner,
          {
            :query => {
              :owner_id => owner.id
            },
            :update => {
              # keep the unread count between 0 and max feed size
              :'$set' => { :count => [[0, count].max, self.class::MAX_FEED_SIZE].min }
            },
            :upsert => true
          }
        )
      end


      private


      @@mongo_indexes ||= {}


      ##
      # Execute the mongo update
      def unread_count_do_update(owner, args)
        begin
          unread_count_collection(owner).find_and_modify(args)
        rescue Mongo::OperationFailure => ex
          raise ex unless self.class::MONGO_ERROR_DUPLICATE_KEY == ex.error_code
        end
      end


      ##
      # Get the mongo collection object
      def unread_count_collection(owner)
        collection = @mongo_db.collection("#{owner.type}.#{self.class::FEED_NAME}.unread_count")

        unless @@mongo_indexes["#{collection.name}.owner_id"]
          collection.ensure_index({:owner_id => Mongo::HASHED})
          collection.ensure_index({:owner_id => Mongo::DESCENDING}, {:unique => true})
        end

        collection
      end


      ##
      # set up consts for containing feed class
      def self.included(other)
        other.const_set('MAX_FEED_SIZE', MAX_UNREAD_COUNT) unless defined? other::MAX_FEED_SIZE
        other.const_set('MONGO_ERROR_DUPLICATE_KEY', MONGO_ERROR_DUPLICATE_KEY) unless defined? other::MONGO_ERROR_DUPLICATE_KEY
      end
    end
  end
end
