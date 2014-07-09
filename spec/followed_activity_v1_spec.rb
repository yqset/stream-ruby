require 'multi_json'
require 'spec_helper'
require 'followed_activity_shared_examples'

describe RealSelf::Stream::FollowedActivityV1, "with a v1 followed activity" do

  describe "#to_activity" do
    it "creates an Activity object from a FollowedActivity" do
      Helpers.init(1)
      followed_activity = RealSelf::Stream::FollowedActivity.from_json(MultiJson.encode(followed_activity(1234)))
      activity = followed_activity.to_activity
      expect(activity).to be_an_instance_of RealSelf::Stream::ActivityV1

      expect(followed_activity.title).to eql activity.title
      expect(followed_activity.published).to eql activity.published
      expect(followed_activity.actor.to_objekt).to eql activity.actor
      expect(followed_activity.verb).to eql activity.verb
      expect(followed_activity.object.to_objekt).to eql activity.object
      expect(followed_activity.target.to_objekt).to eql activity.target
      expect(followed_activity.relatives.length).to eql activity.relatives.length
      expect(followed_activity.uuid).to eql activity.uuid
      expect(followed_activity.prototype).to eql activity.prototype

      followed_activity.relatives.each_index do |index|
        expect(followed_activity.relatives[index].to_objekt).to eql activity.relatives[index]
      end
    end
  end 

  it_should_behave_like "a followed activity", 1
end