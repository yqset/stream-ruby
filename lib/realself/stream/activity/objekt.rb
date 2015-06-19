require 'multi_json'

module RealSelf
  module Stream
    class Objekt
      class << self
        def from_json(json)
          hash = MultiJson.decode(json, { :symbolize_keys => true })
          from_hash(hash)
        end

        def from_hash(hash)
          if hash.has_key? :type
            Objekt.new(hash[:type].downcase, hash[:id])

          else
            Objekt.new(hash[:_type].downcase, hash[:_id])
          end
        end
      end

      attr_accessor :type, :id

      def initialize(type, id)
        @type = type.to_s
        @id = id.to_s
      end

      def to_h
        {:type => @type,:id => @id}
      end

      alias :to_hash :to_h

      def hash
        to_h.hash
      end

      def ==(other)
        other.kind_of?(self.class) and self.to_h == other.to_h
      end

      alias :eql? :==

      def to_s
        MultiJson::encode(to_h)
      end
    end
  end
end
