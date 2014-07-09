module RealSelf
  module Stream
    class ActivityV2 < Activity
      VERSION = 2

      SCHEMA_FILE = File.join(File.dirname(__FILE__), 'activity-schema-v2.json')

      def self.from_hash(hash)
        unless VERSION == hash[:version].to_i
          raise ArgumentError, "wrong activity version.  expected 2, got #{hash[:version].to_s}"
        end

        title = hash[:title]
        published = DateTime.parse(hash[:published])
        actor = Objekt.new(hash[:actor][:type], hash[:actor][:id])
        verb = hash[:verb].to_s
        object = Objekt.new(hash[:object][:type], hash[:object][:id])
        target = Objekt.new(hash[:target][:type], hash[:target][:id]) if hash[:target]
        
        extensions = {}
        hash[:extensions].each {|key, val| extensions[key.to_sym] = Objekt.from_hash(val)} if hash[:extensions]

        uuid = hash[:uuid] || SecureRandom.uuid
        prototype = hash[:prototype] || nil

        ActivityV2.new(title, published, actor, verb, object, target, extensions, uuid, prototype)
      end

      attr_reader :title, :published, :actor, :verb, :object, :target, :extensions, :uuid, :prototype, :version

      def initialize(title, published, actor, verb, object, target, extensions, uuid = SecureRandom.uuid, prototype = nil)
        @version = VERSION
        @title = title.to_s
        @published = published.to_datetime
        @actor = actor
        @verb = verb.to_s
        @object = object
        @target = target
        @extensions = (extensions && extensions.to_hash) || {}
        @uuid = uuid.to_s
        @prototype = prototype ? prototype.to_s : "#{actor.type.to_s}.#{verb.to_s}.#{object.type.to_s}"

        self
      end

      def to_h
        extensions = {}
        @extensions.each do |key, obj|
          extensions[key.to_sym] = obj.to_h
        end

        hash = {
                :title => @title,
                :published => @published.to_s,
                :actor => @actor.to_h,
                :verb => @verb,
                :object => @object.to_h,
                :extensions => extensions,
                :uuid => @uuid.to_s,
                :prototype => @prototype.to_s,
                :version => VERSION
              }

        hash[:target] = @target.to_h unless @target.nil?
        
        hash
      end

      alias :to_hash :to_h

      def to_version(version)
        case version.to_i
        when VERSION
          return self
        when 1
          relatives = @extensions.values
          ActivityV1.new(@title, @published, @actor, @verb, @object, @target, relatives, @uuid, @prototype)
        else
          raise ArgumentError, "unsupported activity version:  #{version.to_s}"
        end
      end 

    end
  end
end