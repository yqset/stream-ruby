require 'spec_helper'

shared_examples RealSelf::Feed::Stateful do |feed|
  before :all do
    @feed.mongo_db   = IntegrationHelper.get_mongo
    @feed.ensure_index :user, background: false
  end

  it_should_behave_like RealSelf::Feed::State::Bookmarkable, @feed
  it_should_behave_like RealSelf::Feed::State::Sessioned, @feed
  it_should_behave_like RealSelf::Feed::State::UnreadCountable, @feed

  before :each do
    @owner = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
  end
end
