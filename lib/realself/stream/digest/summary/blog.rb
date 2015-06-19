require 'multi_json'

module RealSelf
  module Stream
    module Digest
      module Summary
        class Blog < CommentableSummary
          Summary.register_type(:blog, self)
        end
      end
    end
  end
end
