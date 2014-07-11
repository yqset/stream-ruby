require 'spec_helper'

describe RealSelf::Stream::Digest::Summary::Dr do
  include Digest::Helpers

  before :each do
    Digest::Helpers.init(RealSelf::Stream::Digest::Summary::Dr)
  end

  describe "#new" do
    it "creates a new doctor activity summary" do
      activity = dr_author_answer_activity
      dr = activity.actor

      summary = RealSelf::Stream::Digest::Summary.create(dr)
      expect(summary).to be_an_instance_of(RealSelf::Stream::Digest::Summary::Dr)
    end
  end

  describe "#add" do
    it "adds answers correctly" do
      activity = dr_author_answer_activity(nil, nil, 1234, nil)
      dr = activity.actor
      stream_activity = stream_activity(activity, nil, [dr])

      summary = RealSelf::Stream::Digest::Summary.create(dr)
      hash = summary.to_h
      expect(hash[:answer][:count]).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:answer][:count]).to eql 1
      expect(hash[:answer][:last]).to eql activity.object.to_h

      activity2 = dr_author_answer_activity(dr.id)
      stream_activity = stream_activity(activity2, nil, [dr])
      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:answer][:count]).to eql 2
      expect(hash[:answer][:last]).to eql activity2.object.to_h
    end

    it "adds articles correctly" do
      activity = dr_author_article_activity()
      dr = activity.actor
      stream_activity = stream_activity(activity, nil, [dr])

      summary = RealSelf::Stream::Digest::Summary.create(dr)
      hash = summary.to_h
      expect(hash[:article][:count]).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:article][:count]).to eql 1
      expect(hash[:article][:last]).to eql activity.object.to_h

      activity2 = dr_author_article_activity(dr.id)
      stream_activity = stream_activity(activity2, nil, [dr])
      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:article][:count]).to eql 2
      expect(hash[:article][:last]).to eql activity2.object.to_h
    end    

    it "adds videos correctly" do
      activity = dr_author_video_activity()
      dr = activity.actor
      stream_activity = stream_activity(activity, nil, [dr])

      summary = RealSelf::Stream::Digest::Summary.create(dr)
      hash = summary.to_h
      expect(hash[:video][:count]).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:video][:count]).to eql 1
      expect(hash[:video][:last]).to eql activity.object.to_h

      activity2 = dr_author_video_activity(dr.id)
      stream_activity = stream_activity(activity2, nil, [dr])
      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:video][:count]).to eql 2
      expect(hash[:video][:last]).to eql activity2.object.to_h
    end  

    it "adds addresses correctly" do
      activity = dr_create_address_activity()
      dr = activity.actor
      stream_activity = stream_activity(activity, nil, [dr])

      summary = RealSelf::Stream::Digest::Summary.create(dr)
      hash = summary.to_h
      expect(hash[:address][:count]).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:address][:count]).to eql 1
      expect(hash[:address][:last]).to eql activity.object.to_h

      activity2 = dr_create_address_activity(dr.id)
      stream_activity = stream_activity(activity2, nil, [dr])
      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:address][:count]).to eql 2
      expect(hash[:address][:last]).to eql activity2.object.to_h
    end       

    it "adds offers correctly" do
      activity = dr_create_offer_activity()
      dr = activity.actor
      stream_activity = stream_activity(activity, nil, [dr])

      summary = RealSelf::Stream::Digest::Summary.create(dr)
      hash = summary.to_h
      expect(hash[:offer][:count]).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:offer][:count]).to eql 1
      expect(hash[:offer][:last]).to eql activity.object.to_h

      activity2 = dr_create_offer_activity(dr.id)
      stream_activity = stream_activity(activity2, nil, [dr])
      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:offer][:count]).to eql 2
      expect(hash[:offer][:last]).to eql activity2.object.to_h
    end 

    it "handles profile updates correctly" do
      activity = dr_update_dr_activity()
      dr = activity.actor
      stream_activity = stream_activity(activity, nil, [dr])

      summary = RealSelf::Stream::Digest::Summary.create(dr)
      hash = summary.to_h
      expect(hash[:profile]).to eql false

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:profile]).to eql true
    end     

    it "adds photos correctly" do
      activity = dr_upload_photo_activity()
      dr = activity.actor
      stream_activity = stream_activity(activity, nil, [dr])

      summary = RealSelf::Stream::Digest::Summary.create(dr)
      hash = summary.to_h
      expect(hash[:photo][:count]).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:photo][:count]).to eql 1
      expect(hash[:photo][:last]).to eql activity.object.to_h

      activity2 = dr_upload_photo_activity(dr.id)
      stream_activity = stream_activity(activity2, nil, [dr])
      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:photo][:count]).to eql 2
      expect(hash[:photo][:last]).to eql activity2.object.to_h
    end

    it "adds reviews correctly" do
      activity = user_author_review_activity()
      dr = activity.extensions[:dr]
      stream_activity = stream_activity(activity, nil, [dr])

      summary = RealSelf::Stream::Digest::Summary.create(dr)
      hash = summary.to_h
      expect(hash[:review][:count]).to eql 0

      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:review][:count]).to eql 1
      expect(hash[:review][:last]).to eql activity.object.to_h

      activity2 = user_author_review_activity(dr.id)
      stream_activity = stream_activity(activity2, nil, [dr])
      summary.add(stream_activity)
      hash = summary.to_h
      expect(hash[:review][:count]).to eql 2
      expect(hash[:review][:last]).to eql activity2.object.to_h
    end

    it "rejects unknown activity types" do
      activity = user_author_comment_activity
      dr = activity.target
      stream_activity = stream_activity(activity, nil, [dr])

      summary = RealSelf::Stream::Digest::Summary.create(dr)

      expect{ summary.add(stream_activity)}.to raise_error
    end    
  end

end