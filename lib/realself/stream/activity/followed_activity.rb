module RealSelf
  module Stream
    class FollowedActivity < Activity

      class << self   
        private 

        def get_implementation(version)
          case version.to_i
          when 1
            FollowedActivityV1
          else
            raise ArgumentError, "unsupported followed-activity version:  #{version.to_s}"
          end
        end
      end # class << self
    end # FollowedActivityV1
  end # Stream
end # RealSelf