RSpec.configure do |c|
  c.include Helpers
end

shared_examples "coho client" do |activity_version|

  before :each do
    Helpers.init(activity_version)
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

      expect(RealSelf::Stream::Coho).to receive(:followersof).with(activity.actor) { dr_follwers }
      expect(RealSelf::Stream::Coho).to receive(:followersof).with(activity.object) { answer_followers }
      expect(RealSelf::Stream::Coho).to receive(:followersof).with(activity.target) { question_followers }
      expect(RealSelf::Stream::Coho).to receive(:followersof).with(topic) { topic_followers }

      expect(RealSelf::Stream::Coho).to receive(:get_followers).and_call_original

      expect(RealSelf::Stream::Coho.get_followers(activity)).to eql followed_activity
    end
  end

end
