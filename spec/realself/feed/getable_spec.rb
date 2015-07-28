require 'spec_helper'

describe RealSelf::Feed::Getable do

  class TestGetable < RealSelf::Feed::Permanent
    FEED_NAME = :test_getable_feed
    include RealSelf::Feed::Getable
  end

  before(:each) do
    @mongo_db         = double('Mongo::DB')
    @mongo_collection = double('Mongo::Collection')
    @mongo_cursor     = double('Mongo::Cursor')

    @feed_owner = RealSelf::Stream::Objekt.new('user', '1234')

    @test_feed          = TestGetable.new
    @test_feed.mongo_db = @mongo_db

    # allow(@mongo_db).to receive(:collection)
    #   .and_return(@mongo_collection)

    allow(@test_feed).to receive(:collection)
      .and_return(@mongo_collection)
  end

  describe "feed composition" do
    context "illegal composition" do
      it "disallows Getable feeds to be mixed in with Capped feeds" do
        expect{
          class IllegalCompositionFeed < RealSelf::Feed::Capped
            include RealSelf::Feed::Getable
          end
        }.to raise_error(RealSelf::Feed::FeedError, /Getable/)
      end
    end
  end


  describe '#get' do
    before(:each) do
      @default_query = {
        :'object.id'  => @feed_owner.id,
        :redacted     => {:'$ne' => true}
      }

      @default_count    = RealSelf::Feed::Getable::FEED_DEFAULT_PAGE_SIZE
      @default_results  = []

      uct  = user_create_thing_activity
      uut  = user_update_thing_activity
      uct2 = user_create_thing_activity

      results = []
      [uct, uut, uct2].each do |activity|
        sa = RealSelf::Stream::StreamActivity.new(@feed_owner, activity, [activity.actor])
        results << sa.to_h
      end

      @default_response = {
        :count        => @default_results.length,
        :before       => nil,
        :after        => nil,
        :stream_items => @default_results
      }


      expect(@mongo_collection).to receive(:sort)
        .with(:_id => :desc)
        .and_return(@mongo_cursor)

      expect(@mongo_cursor).to receive(:limit)
        .with(@default_count)
        .and_return(@mongo_cursor)

      expect(@mongo_cursor).to receive(:to_a)
        .and_return(@default_results)
    end


    context "default arguments" do
      it "returns a properly formatted response" do
        default_options = {}

        expect(@mongo_collection).to receive(:find)
          .with(
            @default_query,
            default_options)
          .and_return(@mongo_collection)

        response = @test_feed.get(@feed_owner)

        expect(response). to eql @default_response
      end
    end


    context "non-default arguments" do
      it "returns the expected response" do
        before = BSON::ObjectId.new.to_s
        after  = BSON::ObjectId.new.to_s

        id_range_query = {
          :'$gt' => BSON::ObjectId.from_string(before),
          :'$lt' => BSON::ObjectId.from_string(after)
        }

        default_options = {:fields => {:object => 0}}

        @default_query[:_id]        = id_range_query
        @default_response[:before]  = before
        @default_response[:after]   = after

        expect(@test_feed).to receive(:get_id_range_query)
          .with(
            before,
            after)
          .and_call_original

        expect(@mongo_collection).to receive(:find)
          .with(
            @default_query,
            default_options)
          .and_return(@mongo_collection)

        response = @test_feed.get(@feed_owner, @default_count, before, after, {}, false)

        expect(response).to eql @default_response
      end
    end
  end
end
