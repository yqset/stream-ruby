require 'spec_helper'

describe RealSelf::Stream::Digest::Summary::UserMessage do
  include Digest::Helpers

  before :each do
    Digest::Helpers.init(RealSelf::Stream::Digest::Summary::UserMessage)
  end

  describe "#new" do
    it "creates a new user message activity summary" do
      activity = user_send_user_message_activity
      user_message = activity.object

      summary = RealSelf::Stream::Digest::Summary.create(user_message)
      expect(summary).to be_an_instance_of(RealSelf::Stream::Digest::Summary::UserMessage)
    end

    it "must be initialized with the proper object type" do
      object = RealSelf::Stream::Objekt.new('answer', 1234)
      expect{RealSelf::Stream::Digest::Summary.create(object)}.to raise_error
    end
  end

  describe "#add" do
    it "counts the number of messages correctly" do
      activity = user_send_user_message_activity
      recipient = activity.target
      stream_activity = stream_activity(activity, nil, [recipient])
      user_message = content_objekt(1234)

      summary = RealSelf::Stream::Digest::Summary.create(user_message)
      hash = summary.to_h
      expect(hash[:user_message][:count]).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:user_message][:count]).to eql 1

      activity2 = user_send_user_message_activity(nil, nil, recipient.id)
      recipient2 = activity2.target
      stream_activity = stream_activity(activity2, nil, [recipient2])
      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:user_message][:count]).to eql 2
    end

    it "rejects unknown activity types" do
      activity = user_author_comment_activity
      stream_activity = stream_activity(activity, nil, [activity.target])
      user_message = content_objekt(1234)
      summary = RealSelf::Stream::Digest::Summary.create(user_message)

      expect{summary.add(stream_activity)}.to raise_error
    end
  end

end