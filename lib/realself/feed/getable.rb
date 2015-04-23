module RealSelf
  module Feed
    module Getable
      FEED_DEFAULT_PAGE_SIZE = 10 # default nubmer feed items to return

      ##
      # retrieve the feed
      #
      # @param [Objekt] owner   the feed owner
      # @param [Integer] count  the maximum number of items to return
      # @param [String] before  a BSON::ObjectId string
      # @param [String] after   a BSON::ObjecxtId string
      # @param [Hash] query     a hash containing a mongo query to use to filter the results
      #
      # @return [Hash]          {:count => [Integer], :before => [String], :after => [String], :stream_items => [Array]}
      def get(owner, count = FEED_DEFAULT_PAGE_SIZE, before = nil, after = nil, query = {})
        collection = collection(owner) # Implemented by including class

        id_range                  = get_id_range_query(before, after)
        query_options             = {:fields => {:object => 0}} # filter out the item owner

        feed_query                = query
        feed_query[:'object.id']  = owner.id
        feed_query[:_id]          = id_range if id_range
        feed_query[:redacted]     = {:'$ne' => true}  # omit redacted items

        feed = collection.find(feed_query, query_options)
          .sort(:_id => :desc)
          .limit(count)
          .to_a

        # return the '_id' field as 'id'
        # NOTE: hashes returned from mongo use string-based keys
        feed.each do |item|
          item['id'] = item['_id'].to_s
          item.delete('_id')
        end

        # construct the standard response package
        {
          :count        => feed.length,
          :before       => before,
          :after        => after,
          :stream_items => feed
        }
      end


      private

      ##
      # get the id range clause for the mongo query
      #
      # @param [String]   A BSON ObjectID string
      # @param [String]   A BSON ObjectID string
      #
      # @returns [Hash]   A hash to use for limiting the feed query
      def get_id_range_query(before, after)
        return nil if before.nil? and after.nil?

        query = {}
        query[:'$gt'] = BSON::ObjectId.from_string(before) if before
        query[:'$lt'] = BSON::ObjectId.from_string(after) if after

        query
      end


      ##
      # check for illegal composition
      def self.included(other)
        raise(
          FeedError,'Capped feeds may not include Getable'
        ) if other.ancestors.include? RealSelf::Feed::Capped
      end
    end
  end
end
