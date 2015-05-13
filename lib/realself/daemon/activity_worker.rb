module RealSelf
  module Daemon
    class StreamActivityWorker
      include Sneakers::Worker
      include RealSelf::Daemon::Worker

      self.content_type = ContentType::ACTIVITY
    end
  end
end
