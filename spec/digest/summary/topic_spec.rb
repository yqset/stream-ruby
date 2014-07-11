require 'spec_helper'

describe RealSelf::Stream::Digest::Summary::Topic do
  include Digest::Helpers

  before :each do
    Digest::Helpers.init(RealSelf::Stream::Digest::Summary::Topic)
  end

  describe "#new" do
    it "creates a new topic activity summary" do
      activity = user_author_review_activity
      topic = activity.target

      summary = RealSelf::Stream::Digest::Summary.create(topic)
      expect(summary).to be_an_instance_of(RealSelf::Stream::Digest::Summary::Topic)
    end
  end

  describe "#add" do
    it "adds photos correctly" do
      activity = dr_upload_photo_activity()
      dr = activity.actor
      topic = activity.target
      stream_activity = stream_activity(activity, nil, [topic])

      summary = RealSelf::Stream::Digest::Summary.create(topic)
      hash = summary.to_h
      expect(hash[:photo][:count]).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:photo][:count]).to eql 1
      expect(hash[:photo][:last]).to eql activity.object.to_h

      activity2 = dr_upload_photo_activity(dr.id, nil, topic.id)
      stream_activity = stream_activity(activity2, nil, [topic])
      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:photo][:count]).to eql 2
      expect(hash[:photo][:last]).to eql activity2.object.to_h
    end
  end
end