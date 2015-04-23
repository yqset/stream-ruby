require 'spec_helper'

describe RealSelf::Stream::Digest::Summary::User do
  include Digest::Helpers

  before :each do
    Digest::Helpers.init(RealSelf::Stream::Digest::Summary::User)
    @owner = objekt('user', Random::rand(1000..9999))
  end

  describe "#new" do
    it "creates a new user activity summary" do
      activity = user_send_user_message_activity
      recipient = activity.target

      summary = RealSelf::Stream::Digest::Summary.create(recipient)
      expect(summary).to be_an_instance_of(RealSelf::Stream::Digest::Summary::User)
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
      stream_activity = RealSelf::Stream::StreamActivity.new(@owner, activity, [@owner])
      user_message = content_objekt(1234)

      summary = RealSelf::Stream::Digest::Summary.create(recipient)
      hash = summary.to_h
      expect(hash[:user_message][:count]).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:user_message][:count]).to eql 1

      activity2 = user_send_user_message_activity(nil, nil, recipient.id)
      stream_activity = RealSelf::Stream::StreamActivity.new(@owner, activity2, [@owner])
      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:user_message][:count]).to eql 2
    end

    it "silently fails and contniues for unknown activity types" do
      activity = dr_upload_photo_activity
      recipient = activity.actor
      stream_activity = RealSelf::Stream::StreamActivity.new(@owner, activity, [@owner])
      summary = RealSelf::Stream::Digest::Summary.create(@owner)

      expect{summary.add(stream_activity)}.to_not raise_error

      summary2 = RealSelf::Stream::Digest::Summary.create(@owner)

      expect(summary).to eql summary2
    end
  end

end