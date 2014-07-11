# require 'multi_json'
require 'spec_helper'
# require 'stream_spec_helpers'

RSpec.configure do |c|
  c.include Activity::Helpers
end

shared_examples "coho client" do |activity_version|

  before :each do
    Activity::Helpers.init(activity_version)
    @activity = RealSelf::Stream::Activity.from_json(example_activity.to_s)
  end

  describe '#get_followers' do
    it 'takes an activity and finds all of the related followers' do
      followed_activity = RealSelf::Stream::FollowedActivity.from_hash(followed_activity(1234))
      activity = followed_activity.to_activity

      topic_followers = []
      case activity_version
      when 1
        topic_followers = followed_activity.relatives[0].followers
        topic = activity.relatives[0]
      when 2
        topic_followers = followed_activity.extensions[:topic].followers
        topic = activity.extensions[:topic]
      end

      dr_follwers = followed_activity.actor.followers
      answer_followers = followed_activity.object.followers
      question_followers = followed_activity.target.followers

      client = double('RealSelf::Stream::Coho::Client')
      allow(RealSelf::Stream::Coho::Client).to receive(:followersof).with(activity.actor) { dr_follwers }
      allow(RealSelf::Stream::Coho::Client).to receive(:followersof).with(activity.object) { answer_followers }
      allow(RealSelf::Stream::Coho::Client).to receive(:followersof).with(activity.target) { question_followers }
      allow(RealSelf::Stream::Coho::Client).to receive(:followersof).with(topic) { topic_followers }

      expect(RealSelf::Stream::Coho::Client).to receive(:get_followers).and_call_original

      expect(RealSelf::Stream::Coho::Client.get_followers(activity)).to eql followed_activity
    end
  end

end