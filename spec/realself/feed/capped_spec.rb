require 'spec_helper'
require_relative '../helpers'

describe RealSelf::Feed::Capped  do
  include Helpers

  class TestCappedFeed < RealSelf::Feed::Capped
    FEED_NAME = :capped_feed_test.freeze
    MAX_FEED_SIZE = 10.freeze
  end


  before(:each) do
    @mongo_db = double('Mongo::DB')
    @mongo_collection = double('Mongo::Collection')

    activity = Helpers.example_activity

    reason = RealSelf::Stream::Objekt.new('review', '9989')

    @feed_owner = RealSelf::Stream::Objekt.new('user', '1234')

    @stream_activity = RealSelf::Stream::StreamActivity.new(
      @feed_owner,
      activity,
      [reason])

    @feed_name = :capped_feed_test

    @max_size = 10
    @default_count = RealSelf::Feed::Capped::FEED_DEFAULT_PAGE_SIZE

    @update_query = {
      :'object.id' => @feed_owner.id
    }

    @duplicate_match_critera = {:'activity.object' => @stream_activity.activity.object.to_h}

    @before = BSON::ObjectId.new
    @after  = BSON::ObjectId.new

    @object_id = double('BSON::ObjectId')
    allow(BSON::ObjectId).to receive(:new)
      .and_return(@object_id)

    sa = @stream_activity.to_h

    @update_clause = {
      :'$push' => {
        :feed => {
          :'$each' => [{
            :_id => @object_id,
            :activity => sa[:activity],
            :reasons => sa[:reasons]
          }],
          :'$slice' => @max_size * -1
        }
      }
    }

    @mongo_collections = []

    # build mock collections for redaction test
    [
      "user.#{TestCappedFeed::FEED_NAME}",
      "foo.#{(TestCappedFeed::FEED_NAME)}",
      'system.indexes',
      'user.timeline'
    ].each do |name|
      collection = double('Mongo::Collection')
      allow(collection).to receive(:name)
        .and_return(name)

      @mongo_collections << collection
    end

    allow(@mongo_db).to receive(:collections)
      .and_return(@mongo_collections)

    @test_feed = TestCappedFeed.new
    @test_feed.mongo_db = @mongo_db
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
    end
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

        expect(@test_feed.class::FEED_NAME).to eql :capped_feed_test
        expect(@test_feed.class::MAX_FEED_SIZE).to eql 10

        expect(BogusCappedFeed::FEED_NAME).to eql :bogus_feed_test
        expect(BogusCappedFeed::MAX_FEED_SIZE).to eql 99
      end
    end
  end


  describe '#get' do
    before(:each) do
      @default_count    = RealSelf::Feed::Getable::FEED_DEFAULT_PAGE_SIZE

      uct  = user_create_thing_activity
      uut  = user_update_thing_activity
      uct2 = user_create_thing_activity

      results = []
      [uct, uut, uct2].each do |activity|
        sa = RealSelf::Stream::StreamActivity.new(@feed_owner, activity, [activity.actor])
        results << sa.to_h
      end

      @default_results = [{'feed' => results}]

      @default_query = [
        {:'$match'    => {:"object.id" => @feed_owner.id}},
        {:'$unwind'   => "$feed"},
        {:'$match'    => {}},
        {:'$sort'     => {:"feed._id" => 1}},
        {:'$limit'    => @default_count},
        {:'$project'  =>
          {
            :"feed.id"        => "$feed._id",
            :"feed.activity"  => 1,
            :"feed.reasons"   => 1
          }
        },
        {:'$group' =>
          {
            :_id    => "$_id",
            :feed  => {:'$addToSet' => "$feed"}
          }
        }
      ]


      @default_response = {
        :count        => @default_results[0]['feed'].length,
        :before       => nil,
        :after        => nil,
        :stream_items => @default_results[0]['feed']
      }

      allow(@mongo_db).to receive(:collection)
        .and_return(@mongo_collection)
    end


    context "default arguments" do
      it "returns a properly formatted response" do
        expect(@mongo_collection).to receive(:aggregate)
          .with(@default_query)
          .and_return(@default_results)

        response = @test_feed.get(@feed_owner)

        expect(response).to eql @default_response
      end
    end


    context "non-default arguments" do
      it "returns the expected response" do
        before = @before.to_s
        after  = @after.to_s

        id_range_query = {
          :'$gt' => BSON::ObjectId.from_string(before),
          :'$lt' => BSON::ObjectId.from_string(after)
        }

        query = {
          :_id => id_range_query,
          :'activity.object.type' => 'review'
        }

        @default_query[2][:'$match']  = {
          :'feed._id' => id_range_query,
          :'feed.activity.object.type' => 'review'
        }

        @default_response[:before]    = before
        @default_response[:after]     = after

        expect(@test_feed).to receive(:get_id_range_query)
          .with(
            before,
            after)
          .and_call_original

        expect(@mongo_collection).to receive(:aggregate)
          .with(@default_query)
          .and_return(@default_results)

        response = @test_feed.get(@feed_owner, @default_count, before, after, query)

        expect(response).to eql @default_response
      end
    end
  end


  describe "#insert" do
    before(:each) do
      expect(@mongo_db).to receive(:collection)
        .with("#{@feed_owner.type}.#{@feed_name}")
        .and_return(@mongo_collection)
    end


    context "allow duplicate entries" do
      it "calls internal methods with the correct arguments" do
        expect(@test_feed).to receive(:do_insert)
          .with(
            @mongo_collection,
            @feed_owner,
            @update_query,
            @update_clause)
          .and_return({'updatedExisting' => true})

        @test_feed.insert(
          @feed_owner,
          @stream_activity)
      end
    end


    context "require duplicate match critera if no duplicates are allowed" do
      before(:each) do
        @update_query[:feed] = {
            :'$not' => {
            :'$elemMatch' => @duplicate_match_critera
          }
        }
      end


      it "raises an error if no duplicate match criteria is specified" do
        expect{@test_feed.insert(
          @feed_owner,
          @stream_activity,
          false)}
        .to raise_error RealSelf::Feed::FeedError
      end


      it "creates the correct update query and update clause" do
        expect(@test_feed).to receive(:do_insert)
          .with(
            @mongo_collection,
            @feed_owner,
            @update_query,
            @update_clause)
          .and_return({'updatedExisting' => true})

        @test_feed.insert(
          @feed_owner,
          @stream_activity,
          false,
          @duplicate_match_critera)
      end
    end
  end


  describe "#redact" do
    before(:all) do
      @uuid = '1B28BCEA-A9D5-4421-8D9B-39C7F3E25B2C'
    end


    context "invalid UUID" do
      it "raises an error" do
        expect{@test_feed.redact('bogus-uuid')}
          .to raise_error RealSelf::Feed::FeedError
      end
    end


    context "valid UUID" do
      it "does not redact from non-capped feed collections" do
        2.times do |index|
          expect(@mongo_collections[index]).to receive(:update)
            .with(
              {:'feed.activity.uuid' => @uuid},
              {:'$set' => {:'feed.$.activity.redacted' => true}},
              {:upsert => false, :multi => true})
            .and_return({'updatedExisting' => true})
        end

        result = @test_feed.redact(@uuid)

        expect(result.length).to eql 2
        expect(result.include? "user.#{TestCappedFeed::FEED_NAME}").to eql true
        expect(result.include? "foo.#{TestCappedFeed::FEED_NAME}").to eql true
      end
    end
  end

  describe "#do_insert" do
    before(:each) do
      @update_query[:feed] = {
          :'$not' => {
          :'$elemMatch' => @duplicate_match_critera
        }
      }

      expect(@mongo_db).to receive(:collection)
        .with("#{@feed_owner.type}.#{@feed_name}")
        .and_return(@mongo_collection)

      # receive a call to try_insert - first attempt
      expect(@test_feed).to receive(:do_insert)
        .once
        .with(
          @mongo_collection,
          @feed_owner,
          @update_query,
          @update_clause)
        .and_call_original

      # simulate creation of the index
      expect(@mongo_collection).to receive(:name)
        .once
        .and_return("#{@feed_owner.type}.#{@feed_name}")

      expect(@mongo_collection).to receive(:ensure_index)
        .once
        .with(
          {:'object.id' => Mongo::HASHED})

      expect(@mongo_collection).to receive(:ensure_index)
        .once
        .with(
          {:'object.id' => Mongo::DESCENDING},
          {:unique => true})
    end


    context "the capped feed document already exists" do
      it "adds the new activity to the feed if it is not a duplicate" do
        expect(@mongo_collection).to receive(:update)
          .with(
            @update_query,
            @update_clause,
            {:upsert => true})
          .and_return(
            {
              "updatedExisting"=>true,
              "n"=>1,
              "connectionId"=>50,
              "err"=>nil,
              "ok"=>1.0
            })

        expect(@test_feed.insert(
          @feed_owner,
          @stream_activity,
          false,
          @duplicate_match_critera)['updatedExisting']).to eql true
      end

      it "gracefully handles a duplicate key error if the new activity is a duplicate" do
        expect(@mongo_collection).to receive(:update)
          .with(
            @update_query,
            @update_clause,
            {:upsert => true})
          .and_raise Mongo::OperationFailure.new('error', TestCappedFeed::MONGO_ERROR_DUPLICATE_KEY)

        expect(@test_feed.insert(
          @feed_owner,
          @stream_activity,
          false,
          @duplicate_match_critera)).to eql nil
      end
    end


    context "the capped feed document does not already exist" do
      it "upserts the new document" do
        expect(@mongo_collection).to receive(:update)
          .once
          .with(
            @update_query,
            @update_clause,
            {:upsert => true})
          .and_return(
            {
              "updatedExisting"=>false,
              "upserted"=>BSON::ObjectId('5522c5f848e8e1decabdd81d'),
              "n"=>1, "connectionId"=>50,
              "err"=>nil,
              "ok"=>1.0
            })

        result = @test_feed.insert(
          @feed_owner,
          @stream_activity,
          false,
          @duplicate_match_critera)

        expect(result['updatedExisting']).to eql false
        expect(result['upserted']).to_not eql nil
      end

      it "raises an error on unknown mongo operation errors" do
        # attempt to update the collection and simulate a failure
        expect(@mongo_collection).to receive(:update)
          .once
          .with(
            @update_query,
            @update_clause,
            {:upsert => true})
          .and_raise Mongo::OperationFailure.new('error', 99999)

        # expect(@mongo_collection).to receive(:insert)
        #   .with({:object => @feed_owner.to_h, :feed => []})
        #   .and_raise Mongo::OperationFailure.new('error', 99999)

        expect{@test_feed.insert(
          @feed_owner,
          @stream_activity,
          false,
          @duplicate_match_critera)}.to raise_error Mongo::OperationFailure
      end
    end
  end
end
