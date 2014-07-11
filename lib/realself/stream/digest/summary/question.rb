require 'multi_json'

module RealSelf
  module Stream
    module Digest
      module Summary
        class Question < AbstractSummary
          def initialize(object)
            super
            @activities.merge!({:public_note => false, :answer => {:count => 0}})
          end

          def add(stream_activity)
            activity = stream_activity.activity
            case activity.prototype
            when 'dr.author.answer'
              unless activity.target.to_h == @object
                raise ArgumentError, "activity target (question) does not match digest object for activity: #{activity.uuid}"
              end
              @activities[:answer][:count] += 1
              @activities[:answer][:last] = activity.object.to_h
            when 'user.update.question.public_note'
              unless activity.object.to_h == @object
                raise ArgumentError, "activity object (question) does not match digest object for activity: #{activity.uuid}"
              end              
              @activities[:public_note] = true
            else
              super
            end
          end
        end
      end  
    end
  end
end