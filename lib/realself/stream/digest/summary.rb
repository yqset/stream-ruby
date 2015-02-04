# These two need to be required first, because the rest of the summaries depend on them
require 'realself/stream/digest/summary/abstract_summary'
require 'realself/stream/digest/summary/commentable_summary'

# And now require the rest
Dir[File.dirname(__FILE__) + '/summary/*.rb'].each {|file| require file }

module RealSelf
  module Stream
    module Digest
      module Summary

        ##
        # Factory method to construct a new Summary, based on the type of object given
        #
        # @param [Stream::Objekt] object
        def self.create(object)
          begin
            # convert object type to camel case
            # http://stackoverflow.com/questions/4072159/classify-a-ruby-string
            classname = object.type.split('_').collect(&:capitalize).join

            # create an instance of the summary
            klass = RealSelf::Stream::Digest::Summary.const_get(classname)
            klass.new(object)
          rescue Exception => e
            raise "Failed to create unknown summary object type:  #{classname}"
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
