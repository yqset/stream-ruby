require 'multi_json'
# require 'realself/stream/activity'
# require 'realself/stream/objekt'

module RealSelf
  module Stream
    class StreamActivity

      class << self
        def from_hash(hash)
          object = Objekt.from_hash(hash[:object])
          activity = Activity.from_hash(hash[:activity])
          reasons = hash[:reasons].map { |reason| Objekt.from_hash(reason) }

          StreamActivity.new(object, activity, reasons)
        end

        def from_json(json)
          hash = MultiJson::decode(json, { :symbolize_keys => true })
          from_hash(hash)
        end
      end

      attr_accessor :object, :activity, :reasons

      alias :owner :object

      def initialize(object, activity, reasons = [])
        @object = object
        @activity = activity
        @reasons = reasons
      end

      def to_h
        {
          :object => @object.to_h,
          :activity => @activity.to_h,
          :reasons => @reasons.map { |reason| reason.to_h }
        }
      end

      alias :to_hash :to_h

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