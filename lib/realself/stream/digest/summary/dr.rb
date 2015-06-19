require 'multi_json'

module RealSelf
  module Stream
    module Digest
      module Summary
        class Dr < AbstractSummary
          def initialize(object)
            super
            hash = {
              :address => {:count => 0},
              :answer => {:count => 0},
              :article => {:count => 0},
              :offer => {:count => 0},
              :photo => {:count => 0},
              :review => {:count => 0},
              :video => {:count => 0},
              :profile => false
            }
            @activities.merge!(hash)
          end

          def add(stream_activity)
            activity = stream_activity.activity
            case activity.prototype
            when 'dr.author.answer'
              @activities[:answer][:count] += 1
              @activities[:answer][:last] = activity.object.to_h
            when 'dr.author.article'
              @activities[:article][:count] += 1
              @activities[:article][:last] = activity.object.to_h
            when 'dr.author.video'
              @activities[:video][:count] += 1
              @activities[:video][:last] = activity.object.to_h
            when 'dr.create.address'
              @activities[:address][:count] += 1
              @activities[:address][:last] = activity.object.to_h
            when 'dr.create.offer'
              @activities[:offer][:count] += 1
              @activities[:offer][:last] = activity.object.to_h
            when 'dr.update.dr'
              @activities[:profile] = true
            when 'dr.upload.photo'
              @activities[:photo][:count] += 1
              @activities[:photo][:last] = activity.object.to_h
            when 'user.author.review'
              @activities[:review][:count] += 1
              @activities[:review][:last] = activity.object.to_h
            else
              super
            end

            @empty = false
          end

          Summary.register_type(:dr, self)
        end
      end
    end
  end
end
