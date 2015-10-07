module RealSelf
  module Daemon
    class ActivityWorker
      include Sneakers::Worker
      include RealSelf::Daemon::Worker

      @content_type = ContentType::ACTIVITY
    end
  end
end
