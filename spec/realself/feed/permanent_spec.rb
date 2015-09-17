require 'spec_helper'

describe RealSelf::Feed::Permanent  do

  class TestPermanentFeed < RealSelf::Feed::Permanent
    FEED_NAME = :permanent_feed_test.freeze
  end

  before(:each) do
    @feed_owner = RealSelf::Stream::Objekt.new('user', '1234')

    @mongo_db = double('Mongo::DB')
    @mongo_collection = double('Mongo::Collection')
    @collection_name = "#{@feed_owner.type}.#{TestPermanentFeed::FEED_NAME}"

    activity = Helpers.example_activity

    @stream_activity = RealSelf::Stream::StreamActivity.new(
      @feed_owner,
      activity,
      [activity.actor])

    @test_feed = TestPermanentFeed.new
    @test_feed.mongo_db = @mongo_db
  end


  describe "#insert" do
    before(:each) do
      @update_query = {
        :'activity.uuid'  => @stream_activity.activity.uuid,
        :'object.id'      => @feed_owner.id
      }
    end


    it "calls the update method with the correct arguments" do
      expect(@mongo_db).to receive(:collection)
        .with(@collection_name)
        .and_return(@mongo_collection)

      allow(@mongo_collection).to receive(:name)
        .twice
        .and_return(@collection_name)

      expect(@mongo_collection).to receive(:ensure_index)
        .once
        .with(
          {
            :'activity.uuid' => Mongo::DESCENDING,
            :'object.id' => Mongo::DESCENDING
          })

      expect(@mongo_collection).to receive(:ensure_index)
        .once
        .with(
          {
            :'object.id' => Mongo::DESCENDING,
            :'_id'       => Mongo::DESCENDING
          })

      expect(@mongo_collection).to receive(:update)
        .with(
          @update_query,
          @stream_activity.to_h,
          {:upsert => true})

      @test_feed.insert(@feed_owner, @stream_activity)
    end
  end
end
