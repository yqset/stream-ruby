module RealSelf
  module Stream
    module Digest
      module Summary
        class SummaryError < StandardError; end

        @summary_klasses = {}

        ##
        # Factory method to construct a new Summary, based on the type of object given
        #
        # @param [Stream::Objekt] object
        def self.create(object)
          type = object.type.to_sym

          raise SummaryError, "Summary type not registered: #{type}" unless @summary_klasses[type]

          @summary_klasses[type].new(object)
        end

        def self.from_json(json, validate=true)
          array = MultiJson.decode(json, { :symbolize_keys => true })
          Summary.from_array(array)
        end

        def self.from_array(array)
          object = RealSelf::Stream::Objekt.from_hash(array[0])

          summary = Summary.create(object)
          summary.instance_variable_set(:@activities, array[1])

          summary
        end


        def self.register_type(type, klass)
          @summary_klasses[type.to_sym] = klass
        end
      end
    end
  end
end

