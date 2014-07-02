require 'json-schema'
# require 'realself/stream/activity/objekt'
require 'securerandom'

module RealSelf
  module Stream
    class Activity

      class << self   
        @@schema = nil

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

        private

        def get_implementation(version)
          case version.to_i
          when 1
            ActivityV1
          else
            raise ArgumentError, "unsupported activity version:  #{version.to_s}"
          end          
        end
      end

      def ==(other)
        self.to_h == other.to_h
      end

      alias :eql? :==

      def to_s    
        MultiJson.encode(self.to_h)
      end
    end
  end
end