require 'json-schema'
require 'realself/stream/objekt'

module RealSelf
  module Stream
    class Activity

      class << self   
        @@schema = MultiJson.decode(open(File.join(File.dirname(__FILE__), 'activity-schema.json')).read)

        def from_json(json)
          JSON::Validator.validate!(@@schema, json)
          hash = MultiJson.decode(json)

          title = hash['title']
          published = DateTime.parse(hash['published'])
          actor = Objekt.new(hash['actor']['type'], hash['actor']['id'])      
          verb = hash['verb'].to_s
          object = Objekt.new(hash['object']['type'], hash['object']['id'])
          target = Objekt.new(hash['target']['type'], hash['target']['id']) if hash['target']
          relatives = []

          relatives = hash['relatives'].map {|rel| Objekt.new(rel['type'], rel['id'])} if hash['relatives']

          return Activity.new(title, published, actor, verb, object, target, relatives)         
        end
      end

      attr_accessor :title, :published, :actor, :verb, :object, :target, :relatives 

      def initialize(title, published, actor, verb, object, target, relatives)
        @title = title.to_s
        @published = published.to_datetime
        @actor = actor
        @verb = verb.to_s
        @object = object
        @target = target
        @relatives = relatives.to_ary

        self.to_s  # invoke validation

        self
      end

      def ==(other)
        self.to_h == other.to_h
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

      alias :to_hash :to_h

      def to_s    
        json = MultiJson.encode(to_h)
        JSON::Validator.validate!(@@schema, json)
        return json
      end
    end
  end
end