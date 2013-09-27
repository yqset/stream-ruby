require 'httparty'
#require 'realself/stream'
require 'multi_json'
require 'net/http'

module RealSelf
  module Stream
    module Coho
      class Client

        include HTTParty

        class << self
          attr_accessor :logger

          def base_uri=(uri)
            base_uri(uri) # pass on the URI to HTTParty
          end

          def follow(actor, objekt)
            raise "not implemented"
          end

          def unfollow(actor, objekt)
            raise "not implemented"
          end

          def followedby(objekt)
            response = self.get("/followedby/#{objekt.type}/#{objekt.id}")
            validate_response(response)
            parse_objekts(response.body)
          end

          def followersof(objekt)
            begin
              response = self.get("/followersof/#{objekt.type}/#{objekt.id}")
            rescue StandardError => e
              puts e.message
              puts e.backtrace.join("\n")
              raise e
            end
            validate_response(response)
            parse_objekts(response.body)
          end

          def get_followers(activity)

            followed_activity = RealSelf::Stream::FollowedActivity.from_json(activity.to_s, false)

            #actor followers
            followed_activity.actor.followers = Coho::Client.followersof(activity.actor)

            #object followers
            followed_activity.object.followers = Coho::Client.followersof(activity.object)

            #target followers
            followed_activity.target.followers = Coho::Client.followersof(activity.target) if activity.target

            #related objekt followers
            followed_activity.relatives.each do |obj|
              obj.followers = Coho::Client.followersof(obj)
            end

            followed_activity
          end

          private

          def log
            @logger || @logger = Logger.new(STDOUT)
          end

          def parse_objekts(json)
            hash = MultiJson.decode(json)

            objekts = hash.map { |obj| RealSelf::Stream::Objekt.new(obj['type'], obj['id']) }

            objekts unless objekts.empty?
          end

          def validate_response(response)
            unless [200, 204].include? response.code
              raise "Network Error: #{response.code.to_s} - #{response.body}"
            end
          end
        end
      end
    end
  end
end
