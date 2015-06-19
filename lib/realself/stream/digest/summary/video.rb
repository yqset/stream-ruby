require 'multi_json'

module RealSelf
  module Stream
    module Digest
      module Summary
        class Video < CommentableSummary
          Summary.register_type(:video, self)
        end
      end
    end
  end
end
