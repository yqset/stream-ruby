require 'multi_json'
require 'realself/stream/objekt'

module RealSelf
  module Stream
    class QueueObjekt < Objekt

      class << self

        def from_json(json)
          hash = MultiJson.decode(json)

          followers = []
          followers = hash['followers'].map { |obj| Objekt.new(obj['type'], obj['id']) } if hash['followers']

          return QueueObjekt.new(hash['type'], hash['id'], followers)
        end
      end

      attr_accessor :followers

      def initialize(type, id, followers = [])
        super(type, id)
        @followers = followers.to_ary    
      end

      def to_h
        hash = super

        unless @followers.nil?
          hash[:followers] = @followers.map {|follower| follower.to_h}
        end

        return hash
      end

      alias :to_hash :to_h

      def to_objekt
        Objekt.new(@type, @id)
      end
    end
  end
end