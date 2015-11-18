require 'spec_helper'

shared_examples RealSelf::Feed::Redactable do |feed|
  before :all do
    @feed.mongo_db   = IntegrationHelper.get_mongo
    @feed.class.ensure_index :user, background: false, mongo: @feed.mongo_db
  end

  describe '#ensure_index' do
    it 'creates the correct indexes' do
      collection = @feed.send(:get_collection, @owner.type)
      indexes    = collection.indexes.to_a

      # if we're testing a capped collection, use the correct name and key
      prefix = @feed.kind_of?(::RealSelf::Feed::Capped) ? "feed." : ''

      result = indexes.map do |index|
        if prefix + 'activity.redacted_-1' == index[:name]
          expect(index[:key]).to eql({prefix +'activity.redacted' => Mongo::Index::DESCENDING})
          expect(index[:sparse]).to  eql(true)
          index[:name]
        end
      end.compact

      expect(result.size).to eql 1
    end
  end

  describe '#redact' do
    it "redacts activities" do
      owner     = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
      owner2    = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
      activity  = user_create_thing_activity
      activity2 = user_update_thing_activity

      sa        = RealSelf::Stream::StreamActivity.new(
        owner,
        activity,
        [owner])

      sa2       = RealSelf::Stream::StreamActivity.new(
        owner2,
        activity,
        [owner2])

      @feed.insert owner, sa
      @feed.insert owner2, sa2

      sa        = RealSelf::Stream::StreamActivity.new(
        owner,
        activity2,
        [owner])

      sa2       = RealSelf::Stream::StreamActivity.new(
        owner2,
        activity2,
        [owner2])

      @feed.insert owner, sa
      @feed.insert owner2, sa2

      result = @feed.get owner
      expect(result[:count]).to eql 2

      @feed.redact :user, activity.uuid

      result = @feed.get owner
      expect(result[:count]).to eql 1

      result =  @feed.get owner2
      expect(result[:count]).to eql 1

      @feed.redact :user, activity2.uuid

      result = @feed.get owner
      expect(result[:count]).to eql 0

      result =  @feed.get owner2
      expect(result[:count]).to eql 0
    end
  end
end
