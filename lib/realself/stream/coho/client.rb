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
          attr_accessor :logger, :wait_interval

          # Upon failure wait exponentially longer between retries
          def stubborn_get(*args)
            max = 3
            tries ||= 1
            self.get(*args)
          rescue => e
            if tries <= max
              wait = tries * (@wait_interval || 10)
              @logger.error "Encountered the following exception, retrying in #{wait} secs"
              @logger.error "#{e.message} - #{e.backtrace}"
              sleep wait
              tries += 1
              retry
            else
              @logger.error 'Encountered the following exception, exhausted all retry attempts'
              @logger.error "#{e.message} - #{e.backtrace}"
              raise e
            end
          end

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
            response = self.stubborn_get("/followedby/#{objekt.type}/#{objekt.id}")
            validate_response(response)
            parse_objekts(response.body)
          end

          def followersof(objekt)
            begin
              response = self.stubborn_get("/followersof/#{objekt.type}/#{objekt.id}")
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
