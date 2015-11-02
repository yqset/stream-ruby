require 'spec_helper'
require 'mongo'

describe RealSelf::Feed::Capped do
  include Helpers

  class CappedIntegrationTestFeed < RealSelf::Feed::Capped
    FEED_NAME = :capped_integration_test.freeze
    MAX_FEED_SIZE = 10.freeze
    include RealSelf::Feed::UnreadCountable
  end


  before :all do
    @feed           = CappedIntegrationTestFeed.new
    @feed.mongo_db  = IntegrationHelper.get_mongo
    @feed.ensure_index :user, false
  end


  # shared examples
  it_should_behave_like '#insertable', @feed
  it_should_behave_like RealSelf::Feed::Getable, @feed
  it_should_behave_like RealSelf::Feed::Redactable, @feed
  it_should_behave_like RealSelf::Feed::UnreadCountable, @feed


  before :each do
    @owner = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
    @activity         = user_create_thing_activity
    @stream_activity  = RealSelf::Stream::StreamActivity.new(@owner, @activity, [@owner])
  end


  describe "constant assignments" do
    context "use correct constants" do
      it "uses the correct feed name and max size" do
        # declare a class with dissimilar name and size
        # to confirm constants referenced in modules are correct
        class BogusCappedFeed < RealSelf::Feed::Capped
          FEED_NAME = :bogus_feed_test.freeze
          MAX_FEED_SIZE = 99.freeze
        end

        feed = CappedIntegrationTestFeed.new

        expect(feed.class::FEED_NAME).to eql :capped_integration_test
        expect(feed.class::MAX_FEED_SIZE).to eql 10

        expect(BogusCappedFeed::FEED_NAME).to eql :bogus_feed_test
        expect(BogusCappedFeed::MAX_FEED_SIZE).to eql 99
      end
    end
  end


  describe '#ensure_index' do
    it 'creates the correct indexes' do
      collection = @feed.send(:get_collection, @owner.type)
      indexes    = collection.indexes.to_a

      result = indexes.map do |index|
        case index[:name]
        when "_id_"
          index[:name]
        when "object.id_-1"
          expect(index[:key]).to eql({'object.id' => Mongo::Index::DESCENDING})
          index[:name]
        end
      end.compact

      expect(result.size).to eql 2
    end
  end


  describe "feed composition" do
    context "illegal composition" do
      it "disallows Capped feeds to be mixed in with Redactable feeds" do
        expect{
          class IllegalCompositionFeed < RealSelf::Feed::Capped
            include RealSelf::Feed::Redactable
          end
        }.to raise_error(RealSelf::Feed::FeedError, /Redactable/)
      end

      it "disallows Getable feeds to be mixed in with Capped feeds" do
        expect{
          class IllegalCompositionFeed < RealSelf::Feed::Capped
            include RealSelf::Feed::Getable
          end
        }.to raise_error(RealSelf::Feed::FeedError, /Getable/)
      end
    end
  end


  describe '#insert' do
    it "limits the feed to the specified max size" do
      stream_activities = []

      (CappedIntegrationTestFeed::MAX_FEED_SIZE + 1).times do
        activity = user_create_thing_activity
        sa       = RealSelf::Stream::StreamActivity.new(@owner, activity, [@owner])

        stream_activities << sa
        @feed.insert @owner, sa
      end

      result = @feed.get @owner, CappedIntegrationTestFeed::MAX_FEED_SIZE + 1

      expect(CappedIntegrationTestFeed::MAX_FEED_SIZE == result[:count])
      expect(result[:stream_items].count).to eql CappedIntegrationTestFeed::MAX_FEED_SIZE

      stream_activities.reverse!

      result[:stream_items].each_index do |index|
        expect(stream_activities[index]).to eql RealSelf::Stream::StreamActivity.from_hash(result[:stream_items][index].to_hash)
      end
    end


    it "allows duplicates" do
      @feed.insert @owner, @stream_activity, true
      @feed.insert @owner, @stream_activity, true

      result = @feed.get @owner, 2

      result[:stream_items][0].delete 'id'
      result[:stream_items][1].delete 'id'

      expect(result[:stream_items][0]).to eql result[:stream_items][1]
    end


    it "disallows duplicates" do
      @feed.insert @owner, @stream_activity, false, {'activity.object' => @activity.object.to_h}
      @feed.insert @owner, @stream_activity, false, {'activity.object' => @activity.object.to_h}

      result = @feed.get @owner, 2

      expect(result[:count]).to eql 1
    end
  end
end
