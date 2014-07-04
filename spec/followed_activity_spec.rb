require 'multi_json'
require 'spec_helper'
require 'stream_spec_helpers'

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
  end  
end