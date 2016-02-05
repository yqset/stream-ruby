
require 'base64'
require 'realself/stream'
require 'bunny'

module RealSelf
  module Daemon
    module RakeTasks
      def self.process_errors rmq_url, queue_name, content_type
        connection = Bunny.new args[:rmq_url]
        connection.start

        error_queue_name = "#{queue_name}-error"

        ch = connection.channel
        error_queue = ch.queue(error_queue_name, :durable => true)

        message_count = error_queue.message_count
        puts("#{error_queue_name} size: #{message_count}")
        processed = 0;


        error_queue.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, payload|
          begin
            # attempt to parse the original message out of the error message wrapper
            message   = JSON.parse(payload, :symbolize_names => true)
            payload   = Base64.decode64(message[:payload])
            puts "replaying activity:  #{payload}"
            activity  = RealSelf::Stream::Factory.from_json(content_type, payload)

            # publish it back to the originating queue
            publish_queue = ch.queue(queue_name,
              :durable => true,
              :arguments => {
                :'x-dead-letter-exchange' => "#{activity_queue}-retry"
                 # :'x-message-ttl' => 10000  # must match value used in Sneakers.configure in bin/steelhead-daemon
                })

            publish_queue.publish(activity.to_s, {:content_type => content_type})

            # ack the message
            ch.acknowledge(delivery_info.delivery_tag, false)

          rescue StandardError => se
            puts "failed to parse message:  #{payload.to_s}"
            puts "#{se.message}\n#{se.backtrace}"

            # reject the message and requeue it in the error queue
            ch.reject(delivery_info.delivery_tag, true)

          end

          processed += 1

          break if message_count == processed
        end

        puts "processed #{message_count} errors"

        ch.close
        connection.stop
      end
    end
  end
end

desc "Replay messages from an error queue"
task :replay_error_queue, :rmq_url, :original_queue_name, :content_type do |t, args|

  RealSelf::RakeTasks.process_errors args[:rmq_url], args[:original_queue_name], args[:content_type]
end
