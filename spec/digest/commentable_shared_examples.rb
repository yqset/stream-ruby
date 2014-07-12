require 'spec_helper'

RSpec.configure do |c|
  c.include Digest::Helpers
end

shared_examples "a commentable summary" do |commentable_class|

  before :each do
    Digest::Helpers.init(commentable_class)
  end

  describe "#new" do
    it "creates a new commentable activity summary" do
      activity = user_author_comment_activity
      stream_activity(activity, nil, [activity.target])
      comment_target = activity.target

      summary = RealSelf::Stream::Digest::Summary.create(comment_target)
      expect(summary).to be_an_instance_of(commentable_class)
    end

    it "must be initialized with the proper object type" do
      object = RealSelf::Stream::Objekt.new('answer', 1234)
      expect{RealSelf::Stream::Digest::Summary.create(object)}.to raise_error
    end
  end

  describe "#add" do
    it "summarizes comments for a user subscribed to (following) a commentable content item" do
      activity = user_author_comment_activity
      owner = RealSelf::Stream::Objekt.new('user', Random::rand(1000..9999))
      content = activity.target
      stream_activity = stream_activity(activity, owner, [content])

      summary = RealSelf::Stream::Digest::Summary.create(content)
      hash = summary.to_h
    
      expect(hash[:comment][:count]).to eql 0
      expect(hash[:comment_reply].length).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:comment][:count]).to eql 1
      expect(hash[:comment_reply].length).to eql 0

      stream_activity2 = stream_activity(user_author_comment_activity(nil, nil, content.id), owner, [content])
      summary.add(stream_activity2)
      hash = summary.to_h
      expect(hash[:comment][:count]).to eql 2
      expect(hash[:comment_reply].length).to eql 0
    end

    it "summarizes comments for the author of a commentable content item (notifications)" do
      owner = RealSelf::Stream::Objekt.new('user', Random::rand(1000..9999))
      activity = user_author_comment_activity(nil, nil, nil, owner.id) 
      content = activity.target
      stream_activity = stream_activity(activity, owner, [content])

      summary = RealSelf::Stream::Digest::Summary.create(content)
      hash = summary.to_h
      expect(hash[:comment][:count]).to eql 0
      expect(hash[:comment_reply].length).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:comment][:count]).to eql 1
      expect(hash[:comment_reply].length).to eql 0

      stream_activity2 = stream_activity(user_author_comment_activity(nil, nil, content.id, owner.id), owner, [content])
      summary.add(stream_activity2)
      hash = summary.to_h
      expect(hash[:comment][:count]).to eql 2
      expect(hash[:comment_reply].length).to eql 0
    end

    it "summarizes comment replies when the author of a commentable content item is also the author of the parent comment" do
      # discussion author IS author of parent comment
      parent_content_author = RealSelf::Stream::Objekt.new('user', Random::rand(1000..9999))
      parent_comment_author = parent_content_author
      parent_comment = RealSelf::Stream::Objekt.new('comment', Random::rand(1000..9999))
      parent_content = content_objekt()
      summary = RealSelf::Stream::Digest::Summary.create(parent_content)

      # first reply to parent comment
      activity = user_reply_comment_activity(nil, nil, parent_content.id, parent_comment.id, parent_comment_author.id, parent_content_author.id, 'user.reply.comment')
      stream_activity = stream_activity(activity, parent_content_author)
      summary.add(stream_activity)

      hash = summary.to_h
      expect(hash[:comment][:count]).to eql 0
      expect(hash[:comment_reply].length).to eql 1
      expect(hash[:comment_reply][parent_comment.to_h]).to be_an_instance_of(Hash)
      expect(hash[:comment_reply][parent_comment.to_h][:last]).to eql activity.object.to_h
      expect(hash[:comment_reply][parent_comment.to_h][:count]).to eql 1

      # second reply to same parent comment
      activity = user_reply_comment_activity(nil, nil, parent_content.id, parent_comment.id, parent_comment_author.id, parent_content_author.id, 'user.reply.comment')
      stream_activity = stream_activity(activity, parent_content_author)
      summary.add(stream_activity)
      
      hash = summary.to_h
      expect(hash[:comment][:count]).to eql 0
      expect(hash[:comment_reply].length).to eql 1
      expect(hash[:comment_reply][parent_comment.to_h]).to be_an_instance_of(Hash)
      expect(hash[:comment_reply][parent_comment.to_h][:last]).to eql activity.object.to_h
      expect(hash[:comment_reply][parent_comment.to_h][:count]).to eql 2

      # first reply to DIFFERENT parent comment
      parent_comment2 = RealSelf::Stream::Objekt.new('comment', Random::rand(1000..9999)) 
      activity = user_reply_comment_activity(nil, nil, parent_content.id, parent_comment2.id, parent_comment_author.id, parent_content_author.id, 'user.reply.comment')
      stream_activity = stream_activity(activity, parent_content_author)
      summary.add(stream_activity)
      
      hash = summary.to_h
      expect(hash[:comment][:count]).to eql 0
      expect(hash[:comment_reply].length).to eql 2
      expect(hash[:comment_reply][parent_comment2.to_h]).to be_an_instance_of(Hash)
      expect(hash[:comment_reply][parent_comment2.to_h][:last]).to eql activity.object.to_h
      expect(hash[:comment_reply][parent_comment2.to_h][:count]).to eql 1
    end

    it "summarizes comment replies for a user subscribed to (following) a commentable content item" do
      # user is NOT author of parent comment
      # stream_activity exists in :subscriptions stream only
      activity = user_reply_comment_activity
      owner = RealSelf::Stream::Objekt.new('user', Random::rand(1000..9999))
      content = activity.target
      stream_activity = stream_activity(activity, owner, [content])

      summary = RealSelf::Stream::Digest::Summary.create(content)
      summary.add(stream_activity)

      hash = summary.to_h
      expect(hash[:comment][:count]).to eql 1
      expect(hash[:comment_reply].length).to eql 0

      # user IS author of parent comment
      # stream_activity exists in :notifications stream
      # stream_activity exists in :subscriptions stream ???
      activity2 = user_reply_comment_activity(nil, nil, content.id, nil, owner.id)
      content = activity2.target
      stream_activity2 = stream_activity(activity2, owner, [content])
      comment = activity2.object
      parent_comment = activity2.extensions[:parent_comment]

      summary.add(stream_activity2)

      hash = summary.to_h
      expect(hash[:comment][:count]).to eql 1
      expect(hash[:comment_reply].length).to eql 1
      expect(hash[:comment_reply][parent_comment.to_h][:count]).to eql 1
      expect(hash[:comment_reply][parent_comment.to_h][:last]).to eql comment.to_h

    end 

    it "fails to add a stream_activity that doesn't match the summary type"  do
      owner = RealSelf::Stream::Objekt.new('user', Random::rand(1000..9999))
      activity = user_author_comment_activity(nil, nil, nil, owner.id) 
      content = RealSelf::Stream::Objekt.new('video', 1234)
      stream_activity = stream_activity(activity, owner, [content])

      summary = RealSelf::Stream::Digest::Summary.create(content)
      expect{summary.add(stream_activity)}.to raise_error


      activity = user_reply_comment_activity
      stream_activity = stream_activity(activity, owner, [content])
      expect{summary.add(stream_activity)}.to raise_error  
    end

    it "rejects unknown activity types" do
      activity = user_author_comment_activity(nil, nil, nil, nil, 'cron.send.digest')
      stream_activity = stream_activity(activity, nil, [activity.target])
      summary = RealSelf::Stream::Digest::Summary.create(activity.target)
      expect{summary.add(stream_activity)}.to raise_error
    end   
  end      
end