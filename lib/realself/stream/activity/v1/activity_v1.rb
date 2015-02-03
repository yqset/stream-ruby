module RealSelf
  module Stream
    class ActivityV1 < Activity
      VERSION = 1

      SCHEMA_FILE = File.join(File.dirname(__FILE__), 'activity-schema-v1.json')

      def self.from_hash(hash)
        unless hash[:version].nil? || VERSION == hash[:version].to_i
          raise ArgumentError, "wrong activity version.  expected 1, got #{hash[:version].to_s}"
        end

        title = hash[:title]
        published = DateTime.parse(hash[:published])
        actor = Objekt.new(hash[:actor][:type], hash[:actor][:id])
        verb = hash[:verb].to_s
        object = Objekt.new(hash[:object][:type], hash[:object][:id])
        target = Objekt.new(hash[:target][:type], hash[:target][:id]) if hash[:target]
        relatives = []

        relatives = hash[:relatives].map {|rel| Objekt.new(rel[:type], rel[:id])} if hash[:relatives]

        uuid = hash[:uuid] || SecureRandom.uuid

        prototype = hash[:prototype] || nil

        ActivityV1.new(title, published, actor, verb, object, target, relatives, uuid, prototype)
      end

      attr_reader :title, :published, :actor, :verb, :object, :target, :relatives, :uuid, :prototype, :version

      alias :owner :actor

      def initialize(title, published, actor, verb, object, target, relatives, uuid = SecureRandom.uuid, prototype = nil)
        @version = VERSION
        @title = title.to_s
        @published = published.to_datetime
        @actor = actor
        @verb = verb.to_s
        @object = object
        @target = target
        @relatives = (relatives && relatives.to_ary) || []
        @uuid = uuid.to_s
        @prototype = prototype ? prototype.to_s : "#{actor.type.to_s}.#{verb.to_s}.#{object.type.to_s}"

        self
      end

      def to_h
        hash = {
                :title => @title,
                :published => @published.to_s,
                :actor => @actor.to_h,
                :verb => @verb,
                :object => @object.to_h,
                :relatives => @relatives.map {|relative| relative.to_h},
                :uuid => @uuid.to_s,
                :prototype => @prototype.to_s
              }

        hash[:target] = @target.to_h unless @target.nil?

        hash
      end

      alias :to_hash :to_h

      def to_version(version)
        case version.to_i
        when VERSION
          return self
        else
          raise ArgumentError, "unsupported activity version:  #{version.to_s}"
        end
      end

    end
  end
end