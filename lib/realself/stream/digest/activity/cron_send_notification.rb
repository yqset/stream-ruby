module RealSelf
  module Stream
    module Digest
      module Activity
        class CronSendNotification < ActivityHandler
          def handle(activity)
            # get the notification stream for the current user
            user = activity.target
            interval = activity.object.id # notification interval in secs
            stream = RealSelf::Stream::Chum::Client.get_stream(:notifications, user, 0, '', '', interval)
            digest = RealSelf::Stream::Digest::Digest.new(:notifications, user, interval)

            stream[:stream_items].each do |stream_activity|
              digest.add(stream_activity)
            end

            return true
          end
          register_handler('cron.send.notification')
        end
      end     
    end
  end
end