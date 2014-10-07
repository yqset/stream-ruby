require 'realself/stream/digest/summary'

module RealSelf
  module Stream
    module Digest
      class Digest
        VERSION = 1

        def self.from_json(json, validate=true)
          hash = MultiJson.decode(json, { :symbolize_keys => true })
          from_hash(hash)
        end

        def self.from_hash(hash)
          type = hash[:type]
          owner = RealSelf::Stream::Objekt.new(hash[:owner][:type], hash[:owner][:id])
          interval = hash[:interval]
          stats = hash[:stats]

          summaries = {}
          objects = hash[:summaries]

          objects.each do |type, summary_hash|
            summaries[type] = summaries[type] || {}

            summary_hash.each do |object_id, summary_array|
              summary_object = RealSelf::Stream::Objekt.from_hash(summary_array[0])
              summary = RealSelf::Stream::Digest::Summary.from_array(summary_array)
              summaries[type][object_id] = [summary_object, summary]
            end
          end

          uuid = hash[:uuid] || SecureRandom.uuid
          prototype = hash[:prototype] || nil

          self.new(type, owner, interval, summaries, uuid, prototype)
        end

        attr_reader :type, :interval, :owner, :version, :summaries, :uuid, :prototype

        def initialize(type, owner, interval, summaries = {}, uuid = SecureRandom.uuid, prototype = nil)
          @type = type
          @owner = owner
          @interval = interval
          @summaries = summaries
          @uuid = uuid.to_s
          @prototype = prototype ? prototype.to_s : "#{owner.type}.digest.#{type}"
          @version = VERSION
        end

        def add(stream_activity)
          unless stream_activity.object == @owner
            raise ArgumentError, "stream activity does not belong to current digest owner: #{owner.to_s}"
          end

          stream_activity.reasons.each do |reason|
            summary = get_summary(reason)
            summary.add(stream_activity)
          end
        end

        def to_h
          hash = {:stats => {}, :summaries => {}}
          hash[:type] = @type.to_s
          hash[:owner] = @owner.to_h
          hash [:interval] = @interval.to_i
          hash[:uuid] = @uuid.to_s
          hash[:prototype] = @prototype.to_s
          hash[:version] = VERSION

          # collect the stats
          @summaries.each do |type, list|
            hash[:stats][type.to_sym] = list.length
            hash[:summaries][type.to_sym] = hash[:summaries][type.to_sym] || {}
            list.each { |object_id, summary_array| hash[:summaries][type.to_sym][object_id.to_sym] = [summary_array[0].to_h,  summary_array[1].to_h] }
          end

          return hash
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
          MultiJson.encode(self.to_h)
        end

        private

        def get_summary(object)
          @summaries[object.type.to_sym] = @summaries[object.type.to_sym] || {}
          @summaries[object.type.to_sym][object.id.to_sym] || create_summary(object)
          @summaries[object.type.to_sym][object.id.to_sym][1]
        end

        def create_summary(object)
          summary = RealSelf::Stream::Digest::Summary.create(object)

          @summaries[object.type.to_sym][object.id.to_sym] = [object, summary]

          return summary
        end
      end
    end
  end
end