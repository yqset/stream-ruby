Dir[File.dirname(__FILE__) + '/summary/*.rb'].each {|file| require file }

module RealSelf
  module Stream
    module Digest
      module Summary
        def self.create(object)
          klass = RealSelf::Stream::Digest::Summary.const_get(object.type.capitalize)

          begin
            klass.new(object)
          rescue Exception => e
            raise "Failed to create unknown summary object type:  #{object.type}"
          end
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
      end
    end
  end
end