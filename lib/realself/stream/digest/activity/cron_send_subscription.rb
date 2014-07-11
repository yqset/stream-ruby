module RealSelf
  module Stream
    module Digest
      module Activity
        class CronSendSubscription < ActivityHandler
          def handle(activity)
            # get the notification stream for the current user
            user = activity.target
            interval = activity.object.id # notification interval in secs
            stream = RealSelf::Stream::Chum::Client.get_stream(:subscriptions, user, 0, '', '', interval)
            digest = RealSelf::Stream::Digest::Digest.new(:subscriptions, user, interval)

            stream[:stream_items].each do |stream_activity|
              digest.add(stream_activity)
            end

            return true
          end
          register_handler('cron.send.subscription')
        end
      end     
    end
  end
end