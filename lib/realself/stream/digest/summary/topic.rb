require 'multi_json'

module RealSelf
  module Stream
    module Digest
      module Summary
        class Topic < AbstractSummary
          def initialize(object)
            super
            hash = {
              :discussion => {:count => 0},
              :guide => {:count => 0},
              :photo => {:count => 0},
              :question => {:count => 0},
              :review => {:count => 0}
            }
            @activities.merge!(hash)
          end

          def add(stream_activity)
            activity = stream_activity.activity
            case activity.prototype
            when 'dr.upload.photo'
              @activities[:photo][:count] += 1
              @activities[:photo][:last] = activity.object.to_h              
            when 'user.author.question'
              @activities[:question][:count] += 1
              @activities[:question][:last] = activity.object.to_h              
            when 'user.author.discussion'
              @activities[:discussion][:count] += 1
              @activities[:discussion][:last] = activity.object.to_h
            when 'user.author.fuide'
              @activities[:guide][:count] += 1
              @activities[:guide][:last] = activity.object.to_h              
            when 'user.author.review'
              @activities[:review][:count] += 1
              @activities[:review][:last] = activity.object.to_h
            else
              super
            end
          end
        end
      end  
    end
  end
end