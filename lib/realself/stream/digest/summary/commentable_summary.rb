module RealSelf
  module Stream
    module Digest
      module Summary
        class CommentableSummary <  AbstractSummary

          def initialize(object)
            if self.class == CommentableSummary
              raise "Cannot instantiate abstract CommentableSummary class"
            end

            super

            @activities.merge!({:comment => {:count => 0}, :comment_reply => {}})
          end  

          def add(stream_activity)
            activity = stream_activity.activity

            case activity.prototype

            when 'user.author.comment'
              unless activity.target.to_h == @object
                raise ArgumentError, "activity target (discussion) does not match digest object for activity: #{activity.uuid}"
              end

              add_comment(activity.object)

            when 'user.reply.comment'
              unless activity.target.to_h == @object
                raise ArgumentError, "activity target (discussion) does not match digest object for activity: #{activity.uuid}"
              end
              
              add_comment_reply(stream_activity)

            else
              super
            end            
          end

          protected        

          def add_comment(comment)
            @activities[:comment][:count] += 1
            @activities[:comment][:last] = comment.to_h
          end

          def add_comment_reply(stream_activity)
            owner = stream_activity.object
            activity = stream_activity.activity
            comment = activity.object
            parent_comment = activity.extensions[:parent_comment]
            parent_comment_author = activity.extensions[:parent_comment_author]

            # if the owner of the stream_activity is the author of the parent
            # comment, treat the comment as a reply.  Otherwise, treat it as
            # just a regular comment
            if( owner == parent_comment_author )
              @activities[:comment_reply][parent_comment.id] = @activities[:comment_reply][parent_comment.id] || [parent_comment.to_h, {:count => 0}]
              @activities[:comment_reply][parent_comment.id][1][:count] += 1
              @activities[:comment_reply][parent_comment.id][1][:last] = comment.to_h
            else
              add_comment(comment)
            end
          end          
        end
      end  
    end
  end
end