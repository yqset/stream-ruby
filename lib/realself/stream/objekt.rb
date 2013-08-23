require 'multi_json'

module RealSelf
  module Stream
    class Objekt
      class << self
        def from_json(json)
          hash = MultiJson.decode(json)
          Objekt.new(hash['type'], hash['id'])
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

      def ==(other)
        self.to_h == other.to_h
      end

      def to_s
        MultiJson::encode(to_h)
      end
    end
  end
end