require 'httparty'
#require 'realself/stream'
require 'multi_json'
require 'net/http'

module RealSelf
  module Stream
    class BaseHttpClient

      include HTTParty

      class << self
        attr_accessor :logger, :wait_interval

        # Upon failure wait exponentially longer between retries
        def stubborn_get(*args)
          self.stubborn_request(:get, *args)
        end

        def stubborn_post(*args)
          self.stubborn_request(:post, *args)
        end        

        def base_uri=(uri)
          base_uri(uri) # pass on the URI to HTTParty
        end

        protected

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

        def stubborn_request(method, *args)
          max = 3
          tries ||= 1
          
          case method
            when :get then self.get(*args)
            when :post then self.post(*args)
            else
              raise "Unsupported HTTP method: #{method}"
          end
        rescue => e
          if tries <= max
            wait = tries * (@wait_interval || 10)
            @logger.error "Encountered the following exception, retrying in #{wait} secs"
            @logger.error e.message
            sleep wait
            tries += 1
            retry
          else
            @logger.error 'Encountered the following exception, exhausted all retry attempts'
            @logger.error e.message
            raise e
          end          
        end
      end
    end
  end
end
