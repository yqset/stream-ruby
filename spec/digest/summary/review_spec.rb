require 'spec_helper'

describe RealSelf::Stream::Digest::Summary::Review do

  it_should_behave_like "a commentable summary", RealSelf::Stream::Digest::Summary::Review

  include Digest::Helpers

  before :each do
    Digest::Helpers.init(RealSelf::Stream::Digest::Summary::Review)
  end

  describe "#add" do
    it "counts the number of updates correctly" do
      activity = user_update_review_activity(nil, 1234)
      stream_activity = stream_activity(activity, nil, [activity.object])
      review = content_objekt(1234)

      summary = RealSelf::Stream::Digest::Summary.create(review)
      hash = summary.to_h
      expect(hash[:review_entry][:count]).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:review_entry][:count]).to eql 1
      expect(hash[:review_entry][:last]).to eql activity.object.to_h

      activity2 = user_update_review_activity(nil, 1234)
      stream_activity = stream_activity(activity2, nil, [activity2.object])
      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:review_entry][:count]).to eql 2
      expect(hash[:review_entry][:last]).to eql activity2.object.to_h  
    end
  end

end