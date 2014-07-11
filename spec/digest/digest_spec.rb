require 'spec_helper'

describe RealSelf::Stream::Digest::Digest do
  include Digest::Helpers

  before :each do
    @owner = RealSelf::Stream::Objekt.new('user', 2345)
    @digest = RealSelf::Stream::Digest::Digest.new(:notifications, @owner, 86400)
  end

  describe "#new" do
    it "takes three parameters and returns a new instance" do
      expect(@digest).to be_an_instance_of RealSelf::Stream::Digest::Digest
    end
  end

  describe "#add" do
    it "takes a stream activity and adds it to the summary" do
      activity = dr_author_answer_activity(nil, nil, 1234)
      stream_activity = stream_activity(activity, @owner, [activity.target])
      @digest.add(stream_activity)
      hash = @digest.to_h

      expect(hash[:objects][:question].length).to eql 1
      question = RealSelf::Stream::Objekt.from_hash(hash[:objects][:question].values[0][0])
      expect(question).to eql activity.target

      activity2 = user_udpate_question_public_note_activity(nil, 1234)
      stream_activity2 = stream_activity(activity2, @owner, [activity2.object])
      @digest.add(stream_activity2)
      hash = @digest.to_h

      expect(hash[:objects][:question].length).to eql 1
      question = RealSelf::Stream::Objekt.from_hash(hash[:objects][:question].values[0][0])
      expect(question).to eql activity2.object
      expect(hash[:objects][:question][question.id.to_sym][1][:public_note]).to eql true
    end

    it "takes two stream activities and creates two summaries" do
      activity = dr_author_answer_activity
      stream_activity = stream_activity(activity, @owner, [activity.target])
      @digest.add(stream_activity)

      activity2 = dr_author_answer_activity
      stream_activity2 = stream_activity(activity2, @owner, [activity2.target])
      @digest.add(stream_activity2)

      hash = @digest.to_h

      expect(hash[:stats][:question]).to eql 2
      expect(hash[:objects][:question].length).to eql 2

      expect(hash[:objects][:question][activity.target.id.to_sym][0]).to eql activity.target.to_h
      expect(hash[:objects][:question][activity.target.id.to_sym][1]).to be_an_instance_of(Hash)
      expect(hash[:objects][:question][activity2.target.id.to_sym][0]).to eql activity2.target.to_h      
      expect(hash[:objects][:question][activity2.target.id.to_sym][1]).to be_an_instance_of(Hash)
    end

    it "raises an error when the stream_activity owner does not match the digest owner" do
      activity = dr_author_answer_activity
      stream_activity = stream_activity(activity, nil, [activity.target])

      expect{ @digest.add(stream_activity) }. to raise_error
    end
  end

  describe "#==" do
    it "compares two identical digests" do
      digest = RealSelf::Stream::Digest::Digest.new(:notifications, @owner, 86400)
      digest2 = RealSelf::Stream::Digest::Digest.new(:notifications, @owner, 86400)

      activity = dr_author_answer_activity
      stream_activity = stream_activity(activity, @owner, [activity.target])
      digest.add(stream_activity)
      digest2.add(stream_activity)

      activity2 = dr_author_answer_activity
      stream_activity2 = stream_activity(activity2, @owner, [activity2.target])
      digest.add(stream_activity2)
      digest2.add(stream_activity2)

      expect(digest).to eql digest2
    end

    it "compares two different digests" do
      digest = RealSelf::Stream::Digest::Digest.new(:notifications, @owner, 86400)
      digest2 = RealSelf::Stream::Digest::Digest.new(:subscriptions, @owner, 86400)

      activity = dr_author_answer_activity
      stream_activity = stream_activity(activity, @owner, [activity.target])
      digest.add(stream_activity)
      digest2.add(stream_activity)

      activity2 = dr_author_answer_activity
      stream_activity2 = stream_activity(activity2, @owner, [activity2.target])
      digest.add(stream_activity2)
      digest2.add(stream_activity2)

      expect(digest).to_not eql digest2
    end    
  end

  describe "#to_s" do
    it "converts the digest to a JSON string" do
      activity = dr_author_answer_activity
      stream_activity = stream_activity(activity, @owner, [activity.target])
      @digest.add(stream_activity)

      activity2 = dr_author_answer_activity
      stream_activity2 = stream_activity(activity2, @owner, [activity2.target])
      @digest.add(stream_activity2)

      json = @digest.to_s

      hash = MultiJson.decode(json, {:symbolize_keys => true})
      digest = RealSelf::Stream::Digest::Digest.from_json(json)

      expect(hash).to eql @digest.to_h
      expect(@digest).to eql digest
    end
  end

  describe "::from_hash" do
    it "creates a digest from a hash" do
      activity = dr_author_answer_activity
      stream_activity = stream_activity(activity, @owner, [activity.target])
      @digest.add(stream_activity)

      hash = @digest.to_h

      digest = RealSelf::Stream::Digest::Digest.from_hash(hash)

      expect(hash).to eql digest.to_h
      expect(@digest).to eql digest 
    end
  end

  describe "::from_json" do
    it "creates a digest from a json string" do
      activity = dr_author_answer_activity
      stream_activity = stream_activity(activity, @owner, [activity.target])
      @digest.add(stream_activity)

      json = @digest.to_s

      digest = RealSelf::Stream::Digest::Digest.from_json(json)

      expect(@digest).to eql digest
    end
  end
end