require 'multi_json'

module RealSelf
  module Stream
    module Digest
      module Summary
        class Discussion < CommentableSummary
          Summary.register_type(:discussion, self)
        end
      end
    end
  end
end
