require 'json-schema'
# require 'realself/stream/activity'
# require 'realself/stream/objekt'
# require 'realself/stream/followed_objekt'
# require 'realself/stream/stream_activity'

module RealSelf
  module Stream
    class FollowedActivity < Activity

      class << self   
        # @@schema = nil

        # def create(version, *args)
        #   klass = get_implementation(version)
        #   klass.new(*args)
        # end

        # def from_hash(hash)
        #   version = hash[:version] || 1
        #   klass = get_implementation(version)
        #   klass.from_hash(hash)
        # end


        # def from_json(json, validate = true)
        #   if validate
        #     @@schema = @@schema || MultiJson.decode(open(@@schema_file).read)
        #     JSON::Validator.validate!(@@schema, json)
        #   end

        #   hash = MultiJson.decode(json, {:symbolize_keys => true})
        #   from_hash(hash)
        # end

        private 

        def get_implementation(version)
          case version.to_i
          when 1
            FollowedActivityV1
          else
            raise ArgumentError, "unsupported followed-activity version:  #{version.to_s}"
          end
        end
      end # class << self

      # def ==(other)
      #   self.to_h == other.to_h
      # end

      # alias :eql? :==

      # def to_s
      #   MultiJson.encode(self.to_h)
      # end
    end # FollowedActivityV1
  end # Stream
end # RealSelf