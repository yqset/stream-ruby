module RealSelf
  module Feed
    module Redactable

      attr_accessor :mongo_db

      ##
      # marks all instances of an activity as redacted for all owners
      #
      # @param [String]   the UUID of the activity to redact
      #
      # @returns [Array]  an array of collection names that were redacted from
      def redact(activity_uuid)
        raise(
          RealSelf::Feed::FeedError,
          "Invalid UUID: #{activity_uuid}"
        ) unless activity_uuid.match(RealSelf::Stream::Activity::UUID_REGEX)

        redacted_from = []

        @mongo_db.collections.each do |collection|
          # ignore system collections
          next if collection.name.start_with?('system.')

          #ignore collections not managed by this feed class
          next if !collection.name.end_with?(self.class::FEED_NAME.to_s)

          #update all documents that contain the activity
          result = collection.update(
            {:'activity.uuid' => activity_uuid},
            {:'$set' => {:redacted => true}},
            {:upsert => false, :multi => true}
          )

          if result['updatedExisting']
            redacted_from << collection.name
          end
        end

        redacted_from
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
