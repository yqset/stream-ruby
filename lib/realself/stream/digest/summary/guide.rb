require 'multi_json'

module RealSelf
  module Stream
    module Digest
      module Summary
        class Guide < CommentableSummary
          Summary.register_type(:guide, self)
        end
      end
    end
  end
end
