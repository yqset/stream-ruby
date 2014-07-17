# require 'multi_json'
require 'spec_helper'
# require 'stream_spec_helpers'

RSpec.configure do |c|
  c.include Activity::Helpers
end

shared_examples "a followed activity" do |activity_version|

  before :each do
    Activity::Helpers.init(activity_version)
    @followed_activity = RealSelf::Stream::FollowedActivity.from_json(MultiJson.encode(followed_activity(1234)))
  end

  describe "#to_h" do
    it "returns a hash representation of the followed activity" do
      hash = followed_activity(1234)
      expect(@followed_activity.to_h).to eql hash
    end
  end

  describe "#to_version" do
    it "returns itself when the same version is requested" do
      expect(@followed_activity.to_version(activity_version)).to eql @followed_activity
    end

    it "can convert to a version 1 activity" do
      expect{@followed_activity.to_version(1)}.to_not raise_error
      followed_activity_v1 = @followed_activity.to_version(1)
      converted_activity = RealSelf::Stream::FollowedActivity.from_json(followed_activity_v1.to_s)
      expect(converted_activity).to be_an_instance_of RealSelf::Stream::FollowedActivityV1
    end

    it "raises an error when trying to convert to an unknown version" do
      expect{@followed_activity.to_version(0)}.to raise_error
    end
  end  

  describe "#map_followers" do
    it "enumerates all followers of the activity and describes the reason the follower was included" do
      followers_map = {}
      @followed_activity.map_followers do |follower, reason|
        followers_map[reason] = [] if followers_map[reason].nil?
        followers_map[reason] << follower
      end

      followers_map.each do |reason, followers|
        if 'dr' == reason.type
          expect(followers.length).to eql 2
          expect(followers).to include(RealSelf::Stream::Objekt.new('dr', 1234))
          expect(followers).to include(RealSelf::Stream::Objekt.new('user', 2345))
        end

        if 'answer' == reason.type
          expect(followers.length).to eql 3
          expect(followers).to include(
            RealSelf::Stream::Objekt.new('answer', 1050916),
            RealSelf::Stream::Objekt.new('user', 3456),
            RealSelf::Stream::Objekt.new('user', 4567)
          )
        end

        if 'question' == reason.type
          expect(followers.length).to eql 3
          expect(followers).to include(
            RealSelf::Stream::Objekt.new('question', 1048591),
            RealSelf::Stream::Objekt.new('user', 5678),
            RealSelf::Stream::Objekt.new('user', 6789)
          )
        end   

        if 'topic' == reason.type
          expect(followers.length).to eql 3
          expect(followers).to include(
            RealSelf::Stream::Objekt.new('topic', 265299),
            RealSelf::Stream::Objekt.new('user', 7890),
            RealSelf::Stream::Objekt.new('user', 8901)
          )
        end             
      end
    end
  end
end