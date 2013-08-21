require 'multi_json'

module RealSelf
  module Stream
    class Objekt
      attr_accessor :type, :id, :followers

      def initialize(type, id, followers = nil)
        @type = type.to_s
        @id = id.to_s
        @followers = followers.to_ary if followers    
      end

      def to_h
        hash = {:type => @type,:id => @id}

        unless @followers.nil?
          hash[:followers] = @followers.map {|follower| follower.to_h}
        end
        return hash
      end

      def eql?(other)
        self.to_h == other.to_h
      end

      def to_s
        MultiJson::encode(to_h)
      end
    end
  end
end