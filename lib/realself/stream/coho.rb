require 'realself/stream/base_http_client'

module RealSelf
  module Stream
    class Coho < BaseHttpClient

      class << self

        def follow(actor, objekt)
          body = MultiJson.encode({:actor => actor.to_h, :object => objekt.to_h})
          response = self.stubborn_post("/follow", {:body => body})
          validate_response(response)
        end

        def unfollow(actor, objekt)
          body = MultiJson.encode({:actor => actor.to_h, :object => objekt.to_h})
          response = self.stubborn_post("/unfollow", {:body => body})
          validate_response(response)
        end

        def followedby(objekt)
          response = self.stubborn_get("/followedby/#{objekt.type}/#{objekt.id}")
          validate_response(response)
          parse_objekts(response.body)
        end

        def followersof(objekt)
          response = self.stubborn_get("/followersof/#{objekt.type}/#{objekt.id}")
          validate_response(response)
          parse_objekts(response.body)
        end

        def get_followers(activity)

          followed_activity = RealSelf::Stream::FollowedActivity.from_json(activity.to_s, false)

          #actor followers
          followed_activity.actor.followers = followersof(activity.actor)

          #object followers
          followed_activity.object.followers = followersof(activity.object)

          #target followers
          followed_activity.target.followers = followersof(activity.target) if activity.target

          # related items
          related_items = case followed_activity.version
          when 1
            followed_activity.relatives
          when 2
            followed_activity.extensions.values
          else
            raise ArgumentError, "unsupported activity version: #{activity.version}"
          end

          #related objekt followers
          related_items.each do |obj|
            obj.followers = followersof(obj.to_objekt)
          end

          followed_activity
        end
      end
    end
  end
end
