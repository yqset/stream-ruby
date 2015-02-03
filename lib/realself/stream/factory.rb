module RealSelf
  module Stream
    module Factory

      def self.from_hash(content_type, hash)
        case content_type
        when RealSelf::Stream::ContentType::ACTIVITY
          object = RealSelf::Stream::Activity.from_hash(hash)

        when RealSelf::Stream::ContentType::DIGEST_ACTIVITY
          object = RealSelf::Stream::Digest::Digest.from_hash(hash)

        when RealSelf::Stream::ContentType::STREAM_ACTIVITY
          object = RealSelf::Stream::StreamActivity.from_hash(hash)

        else
          raise ArgumentError, "unsupported content type: #{content_type}"
        end

        object
      end


      def self.from_json(content_type, json, validate = true)
        case content_type
        when RealSelf::Stream::ContentType::ACTIVITY
          object = RealSelf::Stream::Activity.from_json(json, validate)

        when RealSelf::Stream::ContentType::DIGEST_ACTIVITY
          object = RealSelf::Stream::Digest::Digest.from_json(json, validate)

        when RealSelf::Stream::ContentType::STREAM_ACTIVITY
          object = RealSelf::Stream::StreamActivity.from_json(json)  #TODO:  Add schema validation support

        else
          raise ArgumentError, "unsupported content type: #{content_type}"
        end

        object
      end

    end
  end
end