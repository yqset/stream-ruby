require 'spec_helper'

describe RealSelf::Stream::Digest::Summary::Question do
  include Digest::Helpers

  before :each do
    Digest::Helpers.init(RealSelf::Stream::Digest::Summary::Question)
    @owner = objekt('user', Random::rand(1000..9999))
  end

  describe "#new" do
    it "creates a new question activity summary" do
      activity = dr_author_answer_activity
      question = activity.target

      summary = RealSelf::Stream::Digest::Summary.create(question)
      expect(summary).to be_an_instance_of(RealSelf::Stream::Digest::Summary::Question)
    end

    it "must be initialized with the proper object type" do
      object = RealSelf::Stream::Objekt.new('answer', 1234)
      expect{RealSelf::Stream::Digest::Summary.create(object)}.to raise_error
    end
  end

  describe "#add" do
    it "counts the number of answers correctly" do
      activity = dr_author_answer_activity(nil, nil, 1234, nil)
      stream_activity = RealSelf::Stream::StreamActivity.new(@owner, activity, [activity.target])
      question = content_objekt(1234)

      summary = RealSelf::Stream::Digest::Summary.create(question)
      hash = summary.to_h
      expect(hash[:answer][:count]).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:answer][:count]).to eql 1

      activity2 = dr_author_answer_activity(nil, nil, 1234, nil)
      stream_activity = RealSelf::Stream::StreamActivity.new(@owner, activity2, [activity.target])
      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:answer][:count]).to eql 2
    end

    it "sets the public note flag correctly" do
      activity = user_update_question_public_note_activity(nil, 1234, nil)
      stream_activity = RealSelf::Stream::StreamActivity.new(@owner, activity, [activity.target])
      question = content_objekt(1234)

      summary = RealSelf::Stream::Digest::Summary.create(question)

      hash = summary.to_h
      expect(hash[:answer][:count]).to eql 0
      expect(hash[:public_note]).to eql false

      summary.add(stream_activity)

      hash = summary.to_h
      expect(hash[:answer][:count]).to eql 0
      expect(hash[:public_note]).to eql true
    end

    it "rejects unknown activity types" do
      activity = dr_upload_photo_activity
      question = objekt('question', Random::rand(1000..9999))
      stream_activity = RealSelf::Stream::StreamActivity.new(@owner, activity, [activity.target])

      summary = RealSelf::Stream::Digest::Summary.create(question)
      expect{summary.add(stream_activity)}.to raise_error
    end
  end

end