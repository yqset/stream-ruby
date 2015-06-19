module RealSelf
  module Stream
    module Digest
      module Summarizable
        attr_accessor :activities

        def initialize(object)
          @empty = true
          @object = object.to_h
          @activities = {}
        end

        def add(stream_activity)
          raise ArgumentError, "unsupported activity type: #{stream_activity.activity.prototype}"
        end

        def empty?
          @empty
        end

        def to_array
          [@object.clone, @activities.clone]
        end

        def to_h
          @activities.clone
        end

        alias :to_hash :to_h

        def ==(other)
          other.kind_of?(self.class) and self.to_h == other.to_h
        end

        alias :eql? :==

        def to_s
          MultiJson.encode(self.to_array)
        end
      end
    end
  end
end

