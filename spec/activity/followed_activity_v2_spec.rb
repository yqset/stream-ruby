# require 'multi_json'
require 'spec_helper'
# require 'followed_activity_shared_examples'

describe RealSelf::Stream::FollowedActivityV2, "with a v2 followed activity" do

  describe "#to_activity" do
    it "creates an ActivityV2 object from a FollowedActivityV2" do
      Activity::Helpers.init(2)
      followed_activity = RealSelf::Stream::FollowedActivity.from_json(MultiJson.encode(followed_activity(1234)))
      activity = followed_activity.to_activity
      expect(activity).to be_an_instance_of RealSelf::Stream::ActivityV2

      expect(followed_activity.title).to eql activity.title
      expect(followed_activity.published).to eql activity.published
      expect(followed_activity.actor.to_objekt).to eql activity.actor
      expect(followed_activity.verb).to eql activity.verb
      expect(followed_activity.object.to_objekt).to eql activity.object
      expect(followed_activity.target.to_objekt).to eql activity.target
      expect(followed_activity.uuid).to eql activity.uuid
      expect(followed_activity.prototype).to eql activity.prototype
      expect(activity.version).to eql 2

      followed_activity.extensions.each do |key, obj|     
        expect(obj.to_objekt).to eql activity.extensions[key]
      end
    end
  end 

  it_should_behave_like "a followed activity", 2
end