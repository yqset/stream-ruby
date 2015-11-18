module RealSelf
  module Stream
    class FollowedActivity < Activity

      class << self

        def create(version, *args)
          klass = get_implementation(version)
          klass.new(*args)
        end

        def from_hash(hash)
          version = hash[:version] || 1
          klass = get_implementation(version)
          klass.from_hash(hash)
        end

        def from_json(json, validate = true)
          hash = MultiJson.decode(json, { :symbolize_keys => true })
          version = hash[:version] || 1
          klass = get_implementation(version)

          if validate
            @@schema = @@schema || MultiJson.decode(open(klass::SCHEMA_FILE).read)
            JSON::Validator.validate!(@@schema, json)
          end

          from_hash(hash)
        end

        def hash
          to_h.hash
        end

        private

        def get_implementation(version)
          case version.to_i
          when 1
            FollowedActivityV1
          when 2
            FollowedActivityV2
          else
            raise ArgumentError, "unsupported followed-activity version:  #{version.to_s}"
          end
        end
      end # class << self
    end # FollowedActivityV1
  end # Stream
end # RealSelf
