module RealSelf
  module Daemon
    class DigestWorker
      include Sneakers::Worker
      include RealSelf::Daemon::Worker

      self.content_type = ContentType::DIGEST_ACTIVITY
    end
  end
end
