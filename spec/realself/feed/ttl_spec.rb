require 'spec_helper'

describe RealSelf::Feed::Ttl  do

  class TestTtlFeed < RealSelf::Feed::Ttl
    FEED_NAME = :ttl_feed_test.freeze
    FEED_TTL_SECONDS = 9999.freeze
  end

  before(:each) do
    @feed_owner = RealSelf::Stream::Objekt.new('user', '1234')

    @mongo_db = double('Mongo::DB')
    @mongo_collection = double('Mongo::Collection')
    @collection_name = "#{@feed_owner.type}.#{TestTtlFeed::FEED_NAME}"

    activity = Activity::Helpers.example_activity

    @stream_activity = RealSelf::Stream::StreamActivity.new(
      @feed_owner,
      activity,
      [activity.actor])

    @test_feed = TestTtlFeed.new
    @test_feed.mongo_db = @mongo_db
  end


  describe "#insert" do
    before(:each) do
      @update_query = {
        :'activity.uuid'  => @stream_activity.activity.uuid,
        :'object.id'      => @feed_owner.id
      }

      @date = Time.now

      expect(Time).to receive(:now)
        .and_return(@date)

      @ttl_index_info = {
        "_id_"=>
        {"v"=>1, "name"=>"_id_", "key"=>{"_id"=>1}, "ns"=>"chum.user.comments"},
       "object.id_-1"=>
        {"v"=>1,
         "name"=>"object.id_-1",
         "key"=>{"object.id"=>-1},
         "ns"=>"chum.user.comments"},
       "activity.uuid_-1"=>
        {"v"=>1,
         "name"=>"activity.uuid_-1",
         "key"=>{"activity.uuid"=>-1},
         "ns"=>"chum.user.comments"},
       "object.id_-1__id_-1"=>
        {"v"=>1,
         "name"=>"object.id_-1__id_-1",
         "key"=>{"object.id"=>-1, "_id"=>-1},
         "ns"=>"chum.user.comments"},
       "created_1"=>
        {"v"=>1,
         "name"=>"created_1",
         "key"=>{"created"=>1},
         "ns"=>"chum.user.comments",
         "expireAfterSeconds"=>TestTtlFeed::FEED_TTL_SECONDS}
       }

      expect(@mongo_db).to receive(:collection)
        .with(@collection_name)
        .and_return(@mongo_collection)

      expect(@mongo_collection).to receive(:name)
        .once
        .and_return(@collection_name)

      expect(@mongo_collection).to receive(:index_information)
        .and_return(@ttl_index_info)
    end


    it "calls the update method with the correct arguments" do
      expect(@mongo_collection).to receive(:ensure_index)
        .once
        .with({:'object.id' => Mongo::HASHED})

      expect(@mongo_collection).to receive(:ensure_index)
        .once
        .with({:'object.id' => Mongo::DESCENDING}, {:unique => true})

      expect(@mongo_collection).to receive(:ensure_index)
        .once
        .with(
          {:created => Mongo::ASCENDING},
          {:expireAfterSeconds => TestTtlFeed::FEED_TTL_SECONDS})

      stream_hash = @stream_activity.to_h
      stream_hash[:created] = @date.utc

      expect(@mongo_collection).to receive(:update)
        .with(
          @update_query,
          stream_hash,
          {:upsert => true})

      @test_feed.insert(@feed_owner, @stream_activity)
    end

    it "raises an error if the TTL has changed" do
      class BadTTLFeed < RealSelf::Feed::Ttl
        FEED_NAME = :ttl_feed_test.freeze
        FEED_TTL_SECONDS = 10.freeze
      end

      test_feed = BadTTLFeed.new
      test_feed.mongo_db = @mongo_db

      expect{test_feed.insert(@feed_owner, @stream_activity)}
        .to raise_error RealSelf::Feed::FeedError
    end
  end
end
