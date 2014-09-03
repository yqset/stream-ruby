require 'multi_json'

module RealSelf
  module Stream
    module Digest
      module Summary
        class Review < CommentableSummary
          def initialize(object)
            super
            @activities.merge!({:review_entry => {:count => 0}})
          end

          def add(stream_activity)
            activity = stream_activity.activity
            case activity.prototype
            when 'user.author.review_entry'
              @activities[:review_entry][:count] += 1
              @activities[:review_entry][:last] = activity.object.to_h
            else
              super
            end
          end
        end
      end  
    end
  end
end