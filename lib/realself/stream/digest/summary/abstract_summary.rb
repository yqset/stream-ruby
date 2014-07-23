module RealSelf
  module Stream
    module Digest
      module Summary
        class AbstractSummary
          def initialize(object)
            classname = self.class.name.split("::").last

            if classname == 'AbstractSummary'
              raise "Cannot instantiate abstract AbstractSummary class"
            end

            #http://stackoverflow.com/questions/1509915/converting-camel-case-to-underscore-case-in-ruby
            unless classname.gsub(/(.)([A-Z])/,'\1_\2').downcase == object.type
              raise ArgumentError, "invalid object type for this summary:  #{object.type}"
            end

            @object = object.to_h
            @activities = {}
          end

          def add(stream_activity)
            raise ArgumentError, "unsupported activity type: #{stream_activity.activity.prototype}"
          end

          def to_array
            [@object.clone, @activities.clone]
          end

          def to_h
            @activities.clone
          end

          alias :to_hash :to_h

          def ==(other)
            self.to_h == other.to_h
          end

          alias :eql? :==

          def to_s
            MultiJson.encode(self.to_array)
          end
        end
      end  
    end
  end
end