module RealSelf
  module Feed
    class Capped
      FEED_DEFAULT_PAGE_SIZE    = 10.freeze # default nubmer feed items to return
      MONGO_ERROR_DUPLICATE_KEY = 11000.freeze

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
            :key        => {:'object.id' => Mongo::Index::DESCENDING},
            :background => background,
            :unique     => true
          },
          {
            :key        => {:'feed.activity.redacted' => Mongo::Index::DESCENDING},
            :background => background,
            :sparse     => true
          },
          {
            :key        => {:'feed.activity.uuid' => Mongo::Index::DESCENDING},
            :background => background
          }
        ])
      end


      ##
      # retrieve the feed
      #
      # @param [Objekt] owner         the feed owner
      # @param [Integer] count        the maximum number of items to return
      # @param [String] before        a BSON::ObjectId string
      # @param [String] after         a BSON::ObjecxtId string
      # @param [Hash] query           a hash containing a mongo query to use to filter the results
      # @param [bool] include_owner   a flag indicating that the stream item owner should be included in each stream_item returned
      # @param [Int] sort             a flag indicating sort order for stream items
      #
      # @return [Hash]          {:count => [Integer], :before => [String], :after => [String], :stream_items => [Array]}
      def get(owner, count = nil, before = nil, after = nil, query = {}, include_owner = true, sort = Mongo::Index::DESCENDING)
        feed_query                            = {}
        count                                 ||= FEED_DEFAULT_PAGE_SIZE
        id_range                              = get_id_range_query(before, after)
        feed_query[:'feed._id']               = id_range if id_range
        feed_query[:'feed.activity.redacted'] = {:'$ne' => true}  # omit redacted items

        feed_query = feed_query.merge(capify_query(query))

        collection = get_collection(owner.type)

        aggregate_query = [
          {:'$match'    => {:'object.id' => owner.id}},
          {:'$unwind'   => '$feed'},
          {:'$match'    => feed_query},
          {:'$sort'     => {:'feed._id' => sort}},
        ]

        aggregate_query << {:'$limit'    => count} unless count.nil?

        aggregate_query << {
          :'$project'  => {
            :'_id' => '$feed._id',
            :'activity' => '$feed.activity',
            :'reasons' => '$feed.reasons'
          }
        }

        feed  = collection.aggregate(aggregate_query).map do |item|
          item['id'] = item['_id'].to_s
          item.delete('_id')
          item['object'] = owner.to_h if include_owner
          item
        end

        return {:count => feed.length, :before => before, :after => after, :stream_items => feed}
      end

      ##
      # Helper method to convert query format
      def capify_query query
        feed_query = {}
        query.each do |key, value|
          if key.to_s.start_with?('$') && value.kind_of?(Array)
            feed_query[key.to_sym] = []
            value.each do |q|
              feed_query[key.to_sym] << capify_query(q)
            end
          else
            feed_query["feed.#{key}".to_sym] = value
          end
        end
        feed_query
      end


      ##
      # Insert a stream activity in to a capped feed
      #
      # @param [ Objekt ] the owner of the feed
      # @param [ StreamActivity ] the stream activity to insert in to the feed
      # @param [ Boolean ] a flag indicating that similar/duplicate items are allowed in the feed
      # @param [ Hash ] a hash containing the criteria to use for detecting duplicates
      def insert(owner, stream_activity, allow_duplicates = false, duplicate_match_criteria = nil)
        collection    = get_collection(owner.type)

        # enforce idempotence based on UUID unless otherwise specified
        duplicate_match_criteria ||= {'activity.uuid' => stream_activity.uuid} unless allow_duplicates

        update_query  = get_update_query(owner, duplicate_match_criteria)
        update        = get_update_clause(stream_activity)

        do_insert(collection, owner, update_query, update)
      end


      ##
      # Redact an activity from all feeds managed by this class
      # Note: If a given owner's capped feed contains multiple
      # instances of the same activity UUID, only one will be
      # marked as redacted.  See '$' positional operator in mongodb
      # documentation:
      # http://docs.mongodb.org/manual/reference/operator/update/positional
      #
      # @param [String] the UUID of the activity to redact
      #
      # @returns [Integer]  The number of owner_type feeds from which the activity was redacted
      def redact(owner_type: 'user', query: {})
        raise(
          RealSelf::Feed::FeedError,
          "Invalid query: #{query}"
        ) unless query.is_a?(Hash) && !query.empty?

        feed_query = {}

        if query.has_key?(:'object.id')
          feed_query[:'object.id'] = query[:'object.id']
          query.delete(:'object.id')
        end

        feed_query = feed_query.merge(capify_query(query))
        exclude_redacted = {:'feed.activity.redacted' => {:'$ne' => true}}.merge(feed_query)

        pipeline = [
          {:'$match' => feed_query},
          {:'$unwind' => '$feed'},
          {:'$match' => exclude_redacted}
        ]

        modified_count = 0
        get_collection(owner_type).aggregate(pipeline).map do |item|
          condition = {:'feed._id' => BSON::ObjectId.from_string(item['feed']['_id'].to_s)}
          condition[:'object.id'] = feed_query[:'object.id'] if feed_query[:'object.id']
          result = get_collection(owner_type).find(condition)
            .update_one(
              {:'$set' => {:'feed.$.activity.redacted' => true}},
              {:upsert => false, :multi => true})

          modified_count += result.modified_count
        end

        modified_count
      end


      private

      ##
      # Get the mongo collection for the feed
      def get_collection(owner_type)
        @mongo_db.collection("#{owner_type}.#{self.class::FEED_NAME}")
      end


      ##
      # do the insert in to the capped feed
      def do_insert(collection, owner, update_query, update)
        # attempt to upsert to the collection
        # if the query fails, we will attempt an insert
        # If the insert fails with a unique index violation
        # assume the container document exists and the new activity
        # is already present in the feed.
        begin
          return collection.find(update_query).update_one(update, {:upsert => true})
        rescue Mongo::Error::OperationFailure => ex
          raise ex unless ex.message =~ /#{self.class::MONGO_ERROR_DUPLICATE_KEY}/
        end

        return nil
      end


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
        query[:'$lt'] = BSON::ObjectId.from_string(before) if before
        query[:'$gt'] = BSON::ObjectId.from_string(after) if after

        query
      end


      ##
      # build the mongodb update parameter for inserting a new activity
      # in to a capped feed
      def get_update_clause(stream_activity)
        sa = stream_activity.to_h
        {
          :'$push' => {
            :feed => {
              :'$each' => [{
                :_id => BSON::ObjectId.new,
                :activity => sa[:activity],
                :reasons => sa[:reasons]
              }],
              :'$slice' => self.class::MAX_FEED_SIZE.to_i.abs * -1
            }
          }
        }
      end


      ##
      # build the mongodb query to use when attempting
      # to insert a new activity in to a capped feed
      def get_update_query(owner, duplicate_match_criteria)
        update_query = {:'object.id'  => owner.id}
        update_query[:feed] = {
          :'$not' =>{
            :'$elemMatch' => duplicate_match_criteria
          }
        } if duplicate_match_criteria

        update_query
      end
    end
  end
end
