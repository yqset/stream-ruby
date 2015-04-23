require 'realself/stream/test/factory'

module Digest
  module Helpers

    include RealSelf::Stream::Test::Factory

    def self.init(commentable_class)
      @@commentable_class = commentable_class
      # http://stackoverflow.com/questions/1509915/converting-camel-case-to-underscore-case-in-ruby
      @@commentable_content_type = commentable_class.name.split("::").last.gsub(/(.)([A-Z])/,'\1_\2').downcase
    end

    def content_objekt(content_id = Random::rand(1000..9999))
      RealSelf::Stream::Objekt.new(@@commentable_content_type, content_id)
    end

    # comment activities
    def user_author_comment_activity_shared(user_id=nil, comment_id=nil, parent_content_type=nil, parent_content_id=nil)
      parent_content_type = parent_content_type || @@commentable_content_type

      return user_author_comment_activity(
        user_id,
        comment_id,
        parent_content_type,
        parent_content_id)
    end

    def user_reply_comment_activity_shared(comment_author_id=nil, comment_id=nil, parent_comment_id=nil, parent_content_type='content', parent_content_id=nil, parent_comment_author_id=nil)
      parent_content_type = parent_content_type || @@commentable_content_type

      user_reply_comment_activity(
        comment_author_id,
        comment_id,
        parent_comment_id,
        parent_content_type,
        parent_content_id,
        parent_comment_author_id)
    end
  end
end


require_relative 'commentable_shared_examples'
require_relative 'summary_shared_examples'
