require 'json-schema'
require 'realself/stream/objekt'

module RealSelf
  module Stream
    class Activity

      class << self   
        @@activity_schema = MultiJson.decode(open(File.join(File.dirname(__FILE__), 'activity-schema.json')).read)
      end

      attr_accessor :title, :published, :actor, :verb, :object, :target, :relatives 

      def initialize(json)
        JSON::Validator.validate!(@@activity_schema, json)
        hash = MultiJson.decode(json)

        @title = hash['title']
        @published = DateTime.parse(hash['published'])
        @actor = Objekt.new(hash['actor']['type'], hash['actor']['id'])      
        @verb = hash['verb'].to_s
        @object = Objekt.new(hash['object']['type'], hash['object']['id']) if hash['object']          
        @target = Objekt.new(hash['target']['type'], hash['target']['id']) if hash['target']
        @relatives = []

        hash['relatives'].each do |objekt|
          @relatives << Objekt.new(objekt['type'], objekt['id'])
        end

      end

      def eql?(other)
        @hash == other.to_h
      end

      def to_h      
        {
          :title => @title,
          :published => @published.to_s,
          :actor => @actor.to_h,
          :verb => @verb,
          :object => @object.to_h,
          :target => @target.to_h,
          :relatives => @relatives.map {|relative| relative.to_h}
        }
      end

      def to_s    
        MultiJson.encode(to_h)
      end
    end
  end
end