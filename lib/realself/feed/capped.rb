module RealSelf
  module Feed
    class Capped
      FEED_DEFAULT_PAGE_SIZE    = 10.freeze # default nubmer feed items to return
      MONGO_ERROR_DUPLICATE_KEY = 11000.freeze

      attr_accessor :mongo_db


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
        feed_query                    = {}
        id_range                      = get_id_range_query(before, after)
        feed_query[:'feed._id']       = id_range if id_range

        query.each do |key, value|
          feed_query["feed.#{key}".to_sym] = value
        end

        collection = @mongo_db.collection("#{owner.type}.#{self.class::FEED_NAME}")

        aggregate_query = [
          {:'$match'    => {:'object.id' => owner.id}},
          {:'$unwind'   => '$feed'},
          {:'$match'    => feed_query},
          {:'$sort'     => {:'feed._id' => Mongo::DESCENDING }},
        ]

        aggregate_query << {:'$limit'    => count} unless count.nil?

        aggregate_query += [
          {:'$project'  => {:'feed.id' => '$feed._id', :'feed.activity' => 1, :'feed.reasons' => 1}},
          {:'$group'    => {:_id => '$_id', :feed => {:'$addToSet' => '$feed'}}}
        ]

        result  = collection.aggregate(aggregate_query)
        feed    =  result[0] ? result[0]['feed'] : []

        feed.each do |item|
          item['id'] = item['id'].to_s
        end

        return {:count => feed.length, :before => before, :after => after, :stream_items => feed}
      end


      ##
      # Insert a stream activity in to a capped feed
      #
      # @param [ Objekt ] the owner of the feed
      # @param [ StreamActivity ] the stream activity to insert in to the feed
      # @param [ Boolean ] a flag indicating that similar/duplicate items are allowed in the feed
      # @param [ Hash ] a hash containing the criteria to use for detecting duplicates
      def insert(owner, stream_activity, allow_duplicates = true, duplicate_match_criteria = nil)
        collection    = @mongo_db.collection("#{owner.type}.#{self.class::FEED_NAME}")

        update_query  = get_update_query(
                          owner,
                          allow_duplicates,
                          duplicate_match_criteria)

        update = get_update_clause(stream_activity)

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
      # @returns [Array]  an array of collection names that were redacted from
      def redact(activity_uuid)
        raise(
          FeedError,
          "Invalid UUID: #{activity_uuid}"
        ) unless activity_uuid.match(RealSelf::Stream::Activity::UUID_REGEX)

        redacted_from = []

        @mongo_db.collections.each do |collection|
          # ignore system collections
          next if collection.name.start_with?('system.')

          #ignore collections not managed by this feed class
          next if !collection.name.end_with?(self.class::FEED_NAME.to_s)

          result = collection.update(
            {:'feed.activity.uuid' => activity_uuid},
            {:'$set' => {:'feed.$.activity.redacted' => true}},
            {:upsert => false, :multi => true})

          if result['updatedExisting']
            redacted_from << collection.name
          end
        end

        redacted_from
      end


      private

      @@mongo_indexes ||= {}


      ##
      # do the insert in to the capped feed
      def do_insert(collection, owner, update_query, update)
        # ensure indexes
        unless @@mongo_indexes["#{collection.name}.object.id"]
          collection.ensure_index({:'object.id' => Mongo::HASHED})
          collection.ensure_index({:'object.id' => Mongo::DESCENDING}, {:unique => true})
        end

        # attempt to upsert to the collection
        # if the query fails, we will attempt an insert
        # If the insert fails with a unique index violation
        # assume the container document exists and the new activity
        # is already present in the feed.
        begin
          return collection.update(update_query, update, {:upsert => true})
        rescue Mongo::OperationFailure => ex
          raise ex unless self.class::MONGO_ERROR_DUPLICATE_KEY == ex.error_code
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
      def get_update_query(owner, allow_duplicates, duplicate_match_criteria)
        # create the update query
        update_query = {:'object.id' => owner.id}

        # add the criteria by which we will detect duplicates in the feed if necessary
        unless allow_duplicates
          raise(
            FeedError,
            "Missing duplicate match criteria"
          ) unless duplicate_match_criteria

          update_query[:feed] =
          {
            :'$not' =>{
              :'$elemMatch' => duplicate_match_criteria
            }
          }
        end

        update_query
      end
    end
  end
end
