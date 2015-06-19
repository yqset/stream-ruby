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
              @activities[:answer][:count] += 1
              @activities[:answer][:last] = activity.object.to_h
            when 'user.update.question.public_note'
              @activities[:public_note] = true
            else
              super
            end

            @empty = false
          end

          Summary.register_type(:question, self)
        end
      end
    end
  end
end
