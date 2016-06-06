module RealSelf
  module Feed
    module Stateful

      attr_accessor :mongo_db

      SESSION_SECOND = 60 * 30.freeze # 30 minutes in seconds
      MAX_UNREAD_COUNT = 2147483647.freeze
      MONGO_ERROR_DUPLICATE_KEY = 11000.freeze

      def get_state(owner)
          result = state_collection(owner.type).find(
            {:owner_id => owner.id}
          ).limit(1)

          result.first ||  {:owner_id => owner.id}
      end

      private

      ##
      # Execute the mongo update
      def state_do_update(owner, query, update)
        begin
          state_collection(owner.type)
            .find_one_and_update(query, update, {:upsert => true, :return_document => :after})
        rescue Mongo::Error::OperationFailure => ex
          raise ex unless ex.message =~ /#{self.class::MONGO_ERROR_DUPLICATE_KEY}/
        end
      end


      ##
      # Get the mongo collection object
      def state_collection(owner_type)
        @mongo_db.collection("#{owner_type}.#{self.class::FEED_NAME}.state")
      end


      ##
      # set up consts for containing feed class
      def self.included(other)
        other.const_set('MAX_FEED_SIZE', MAX_UNREAD_COUNT) unless defined? other::MAX_FEED_SIZE
        other.const_set('MONGO_ERROR_DUPLICATE_KEY', MONGO_ERROR_DUPLICATE_KEY) unless defined? other::MONGO_ERROR_DUPLICATE_KEY
        other.class_eval do
          include State::UnreadCount
          include State::Bookmark
          include State::Timer
        end
      end
    end
  end
end


