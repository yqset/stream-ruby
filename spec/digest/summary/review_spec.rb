require 'spec_helper'

describe RealSelf::Stream::Digest::Summary::Review do

  it_should_behave_like "a commentable summary", RealSelf::Stream::Digest::Summary::Review

  include Digest::Helpers

  before :each do
    Digest::Helpers.init(RealSelf::Stream::Digest::Summary::Review)
    @owner = objekt('user', Random::rand(1000..9999))
  end

  describe "#add" do
    it "counts the number of entries correctly" do
      activity = user_author_review_entry_activity(nil, 1234)
      stream_activity = RealSelf::Stream::StreamActivity.new(@owner, activity, [activity.object])
      review = content_objekt(1234)

      summary = RealSelf::Stream::Digest::Summary.create(review)
      hash = summary.to_h
      expect(hash[:review_entry][:count]).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:review_entry][:count]).to eql 1
      expect(hash[:review_entry][:last]).to eql activity.object.to_h

      activity2 = user_author_review_entry_activity(nil, 1235)
      stream_activity = RealSelf::Stream::StreamActivity.new(@owner, activity2, [activity2.object])
      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:review_entry][:count]).to eql 2
      expect(hash[:review_entry][:last]).to eql activity2.object.to_h  
    end
  end

end