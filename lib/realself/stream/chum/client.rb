require 'realself/stream/base_http_client'

module RealSelf
  module Stream
    module Chum
      class Client < BaseHttpClient
        STREAM_TYPES = [:messages, :newsfeed, :notifications, :subscriptions, :timeline]

        class << self

          def get_stream(type, owner, count = 10, before = '', after = '', interval = '', mark_as_read = false, include_owner = true)
            unless STREAM_TYPES.include?(type.to_sym)
              raise ArgumentError, "Unknown stream type:  #{type}"
            end

            response = self.stubborn_get("/#{type}/#{owner.type}/#{owner.id}?count=#{count}&before=#{before}&after=#{after}&interval=#{interval}&mark_as_read=#{mark_as_read}&include_owner=#{include_owner}")
            validate_response(response)         
            parse_stream(response.body)
          end

          def get_unread_count(type, owner)
            unless STREAM_TYPES.include?(type.to_sym)
              raise ArgumentError, "Unknown stream type:  #{type}"
            end

            response = self.stubborn_get("/#{type}/#{owner.type}/#{owner.id}/unread_count")
            validate_response(response)
            hash = MultiJson.decode(response.body)
            hash['count']
          end

          protected

          def parse_stream(json)
            hash = MultiJson.decode(json, { :symbolize_keys => true })
            stream_items = hash[:stream_items].map { |obj| RealSelf::Stream::StreamActivity.from_hash(obj) }
            hash[:stream_items] = stream_items

            hash
          end          
        end
      end
    end
  end
end