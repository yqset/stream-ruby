require 'spec_helper'

describe RealSelf::Stream::Digest::Summary::Topic do
  include Digest::Helpers

  before :each do
    Digest::Helpers.init(RealSelf::Stream::Digest::Summary::Topic)
    @owner = objekt('user', Random::rand(1000..9999))
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
      stream_activity = RealSelf::Stream::StreamActivity.new(@owner, activity, [topic])

      summary = RealSelf::Stream::Digest::Summary.create(topic)
      hash = summary.to_h
      expect(hash[:photo][:count]).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:photo][:count]).to eql 1
      expect(hash[:photo][:last]).to eql activity.object.to_h

      activity2 = dr_upload_photo_activity(dr.id, nil, topic.id)
      stream_activity = RealSelf::Stream::StreamActivity.new(@owner, activity2, [topic])
      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:photo][:count]).to eql 2
      expect(hash[:photo][:last]).to eql activity2.object.to_h
    end

    it "adds questions correctly" do
      activity = user_author_question_activity()
      user = activity.actor
      topic = activity.target
      stream_activity = RealSelf::Stream::StreamActivity.new(@owner, activity, [topic])

      summary = RealSelf::Stream::Digest::Summary.create(topic)
      hash = summary.to_h
      expect(hash[:question][:count]).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:question][:count]).to eql 1
      expect(hash[:question][:last]).to eql activity.object.to_h

      activity2 = user_author_question_activity(user.id, nil, topic.id)
      stream_activity = RealSelf::Stream::StreamActivity.new(@owner, activity2, [topic])
      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:question][:count]).to eql 2
      expect(hash[:question][:last]).to eql activity2.object.to_h
    end

    it "adds discussions correctly" do
      activity = user_author_discussion_activity()
      user = activity.actor
      topic = activity.target
      stream_activity = RealSelf::Stream::StreamActivity.new(@owner, activity, [topic])

      summary = RealSelf::Stream::Digest::Summary.create(topic)
      hash = summary.to_h
      expect(hash[:discussion][:count]).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:discussion][:count]).to eql 1
      expect(hash[:discussion][:last]).to eql activity.object.to_h

      activity2 = user_author_discussion_activity(user.id, nil, topic.id)
      stream_activity = RealSelf::Stream::StreamActivity.new(@owner, activity2, [topic])
      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:discussion][:count]).to eql 2
      expect(hash[:discussion][:last]).to eql activity2.object.to_h
    end

    it "adds guides correctly" do
      activity = user_author_guide_activity()
      user = activity.actor
      topic = activity.target
      stream_activity = RealSelf::Stream::StreamActivity.new(@owner, activity, [topic])

      summary = RealSelf::Stream::Digest::Summary.create(topic)
      hash = summary.to_h
      expect(hash[:guide][:count]).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:guide][:count]).to eql 1
      expect(hash[:guide][:last]).to eql activity.object.to_h

      activity2 = user_author_guide_activity(user.id, nil, topic.id)
      stream_activity = RealSelf::Stream::StreamActivity.new(@owner, activity2, [topic])
      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:guide][:count]).to eql 2
      expect(hash[:guide][:last]).to eql activity2.object.to_h
    end

    it "adds reviews correctly" do
      activity = user_author_review_activity()
      user = activity.actor
      topic = activity.target
      stream_activity = RealSelf::Stream::StreamActivity.new(@owner, activity, [topic])

      summary = RealSelf::Stream::Digest::Summary.create(topic)
      hash = summary.to_h
      expect(hash[:review][:count]).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:review][:count]).to eql 1
      expect(hash[:review][:last]).to eql activity.object.to_h

      activity2 = user_author_review_activity(user.id, nil, nil, topic.id)
      stream_activity = RealSelf::Stream::StreamActivity.new(@owner, activity2, [topic])
      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:review][:count]).to eql 2
      expect(hash[:review][:last]).to eql activity2.object.to_h
    end

    it "rejects unknown activity types" do
      activity = user_request_change_email
      topic = objekt('topic', Random::rand(1000..9999))
      stream_activity = RealSelf::Stream::StreamActivity.new(@owner, activity, [activity.actor])

      summary = RealSelf::Stream::Digest::Summary.create(topic)
      expect{summary.add(stream_activity)}.to raise_error
    end                  
  end
end