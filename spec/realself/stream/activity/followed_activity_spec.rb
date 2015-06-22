describe RealSelf::Stream::FollowedActivity do

  describe "::from_json" do
    it "can create a version 1 followed_activity" do
      Helpers.init(1)
      followed_activity = RealSelf::Stream::FollowedActivity.from_json(MultiJson.encode(followed_activity(1234)))
      expect(followed_activity).to be_an_instance_of RealSelf::Stream::FollowedActivityV1
      expect(followed_activity).to be_an_kind_of RealSelf::Stream::FollowedActivity
      expect(followed_activity).to be_an_kind_of RealSelf::Stream::Activity
    end

    it "can create a version 2 followed_activity" do
      Helpers.init(2)
      followed_activity = RealSelf::Stream::FollowedActivity.from_json(MultiJson.encode(followed_activity(1234)))
      expect(followed_activity).to be_an_instance_of RealSelf::Stream::FollowedActivityV2
      expect(followed_activity).to be_an_kind_of RealSelf::Stream::FollowedActivity
      expect(followed_activity).to be_an_kind_of RealSelf::Stream::Activity
    end
  end

  describe "::from_hash" do
    it "can create a version 1 followed_activity" do
      Helpers.init(1)
      followed_activity = RealSelf::Stream::FollowedActivity.from_hash(followed_activity(1234))
      expect(followed_activity).to be_an_instance_of RealSelf::Stream::FollowedActivityV1
      expect(followed_activity).to be_an_kind_of RealSelf::Stream::FollowedActivity
      expect(followed_activity).to be_an_kind_of RealSelf::Stream::Activity
    end

    it "can create a version 2 followed_activity" do
      Helpers.init(2)
      followed_activity = RealSelf::Stream::FollowedActivity.from_hash(followed_activity(1234))
      expect(followed_activity).to be_an_instance_of RealSelf::Stream::FollowedActivityV2
      expect(followed_activity).to be_an_kind_of RealSelf::Stream::FollowedActivity
      expect(followed_activity).to be_an_kind_of RealSelf::Stream::Activity
    end

    it "raises an error when trying to create an unknown version" do
      Helpers.init(0)
      hash = followed_activity(1234)
      expect{RealSelf::Stream::FollowedActivity.from_hash(hash)}.to raise_error
    end
  end

  describe "#hash" do
    it "supports hash key equality" do
      Helpers.init(2)
      fa1 = RealSelf::Stream::FollowedActivity.from_hash(followed_activity(1234))
      fa2 = RealSelf::Stream::FollowedActivity.from_hash(followed_activity(1234))

      expect(fa1.object_id).to_not eql(fa2.object_id)
      e = {}

      e[fa1] = 123

      expect(e.include?(fa2)).to eql(true)
    end
  end
end
