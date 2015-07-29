require 'spec_helper'

describe RealSelf::Feed::UnreadCountable do

  class TestUnreadCount
    FEED_NAME = :unread_count_feed_test.freeze
    MAX_FEED_SIZE = 10.freeze
    include RealSelf::Feed::UnreadCountable
  end

  class NoMaxSizeFeed
    FEED_NAME = :unread_count_feed_test.freeze
    include RealSelf::Feed::UnreadCountable
  end


  before(:each) do
    @mongo_db = double('Mongo::DB')
    @mongo_collection = double('Mongo::Collection')
    @mongo_cursor     = double('Mongo::Cursor')

    @owner = RealSelf::Stream::Objekt.new('user', '1234')

    @test_feed = TestUnreadCount.new
    @test_feed.mongo_db = @mongo_db

    @update_statement = {
      :query => {
        :owner_id => @owner.id
      },
      :update => {},
      :upsert => true
    }

    allow(@mongo_collection).to receive(:ensure_index)
      .once
      .with({:owner_id => Mongo::HASHED})

    allow(@mongo_collection).to receive(:ensure_index)
      .once
      .with({:owner_id => Mongo::DESCENDING}, {:unique => true})
  end


  describe "constant assignments" do
    context "use correct constants" do
      it "uses the correct feed name and max size" do
        # declare a class with dissimilar name and size
        # to confirm constants referenced in modules are correct
        class BogusUnreadCountFeed
          FEED_NAME = :bogus_feed_test.freeze
          MAX_FEED_SIZE = 99.freeze
          include RealSelf::Feed::UnreadCountable
        end

        expect(@test_feed.class::FEED_NAME).to eql :unread_count_feed_test
        expect(@test_feed.class::MAX_FEED_SIZE).to eql 10

        expect(BogusCappedFeed::FEED_NAME).to eql :bogus_feed_test
        expect(BogusCappedFeed::MAX_FEED_SIZE).to eql 99
      end
    end
  end


  describe "#decrement_unread_count" do
    before(:each) do
      @update_statement[:query][:count]   = { :'$gt' => 0 }
      @update_statement[:update]          = {:'$inc' => { :count => -1}}
    end


    it "does the update with the correct arguments" do
      expect(@test_feed).to receive(:unread_count_do_update)
        .with(
          @owner,
          @update_statement
        )

        @test_feed.decrement_unread_count(@owner)
    end
  end


  describe '#find_with_unread' do
    before(:each) do
      collection_name = "#{@owner.type}.#{TestUnreadCount::FEED_NAME}.unread_count"

      expect(@mongo_db).to receive(:collection)
        .with(collection_name)
        .and_return(@mongo_collection)

      allow(@mongo_collection).to receive(:name)
        .twice
        .and_return(collection_name)
    end


    it "uses the correct mongo query and formats the results" do
      object_id = BSON::ObjectId.new

      query = {
        :_id => {
          :'$gt' => object_id
        },
        :count => {
          :'$gte' => 1
        }
      }

      raw_result = [
        {
          '_id'       => BSON::ObjectId.from_string('000000000000000000000000'),
          'count'     => 10,
          'owner_id'  => '123456'
        }
      ]

      formatted_result = [
        {
          'id'       => '000000000000000000000000',
          'count'     => 10,
          'owner_id'  => '123456'
        }
      ]

      expect(@mongo_collection).to receive(:find)
        .with(query)
        .and_return(@mongo_collection)

      expect(@mongo_collection).to receive(:limit)
        .with(10)
        .and_return(@mongo_cursor)

      expect(@mongo_cursor).to receive(:to_a)
        .and_return(raw_result)

      result = @test_feed.find_with_unread(:user, 1, 10, object_id.to_s)

      expect(result).to eql formatted_result
    end
  end


  describe "#get_unread_count" do
    before(:each) do
      collection_name = "#{@owner.type}.#{TestUnreadCount::FEED_NAME}.unread_count"

      expect(@mongo_db).to receive(:collection)
        .with(collection_name)
        .and_return(@mongo_collection)

      expect(@mongo_collection).to receive(:name)
        .and_return(collection_name)
    end

    it "uses the correct mongo query" do
      expect(@mongo_collection).to receive(:find_one)
        .with(
          {:owner_id => @owner.id},
          {:fields => {:_id => 0}})
        .and_return({:owner_id => @owner.id, :count => 1})

      result = @test_feed.get_unread_count(@owner)

      expect(result[:count]).to eql 1
    end
  end

  describe "#increment_unread_count" do
    before(:each) do
      @update_statement[:update] = {:'$inc' => { :count => 1}}
    end

    context "max feed size" do
      it "uses the default size when the class does not specify one" do
        @update_statement[:query][:count] = {
          :'$lt' => RealSelf::Feed::UnreadCountable::MAX_UNREAD_COUNT
        }

        @test_feed = NoMaxSizeFeed.new

        expect(@test_feed).to receive(:unread_count_do_update)
          .with(
            @owner,
            @update_statement
          )

          @test_feed.increment_unread_count(@owner)
      end


      it "uses the correct size when the class specifies one" do
        @update_statement[:query][:count] = {
          :'$lt' => 10
        }

        expect(@test_feed).to receive(:unread_count_do_update)
          .with(
            @owner,
            @update_statement
          )

          @test_feed.increment_unread_count(@owner)
      end
    end
  end


  describe "#reset_unread_count" do
    it "delegates to set_unread_count" do
      expect(@test_feed).to receive(:set_unread_count)
        .with(@owner, 0)

      @test_feed.reset_unread_count(@owner)
    end
  end


  describe "#set_unread_count" do
    context "default max feed size" do
      before(:each) do
        @test_feed = NoMaxSizeFeed.new
      end


      it "uses the correct max size if the specified count is too big" do
        max_size = RealSelf::Feed::UnreadCountable::MAX_UNREAD_COUNT

        @update_statement[:update] = {
          :'$set' => {:count => max_size}
        }

        expect(@test_feed).to receive(:unread_count_do_update)
          .with(@owner, @update_statement)

        @test_feed.set_unread_count(@owner, max_size + 1)
      end

      it "rounds negative unread counts to zero" do
        @update_statement[:update] = {
          :'$set' => {:count => 0}
        }

        expect(@test_feed).to receive(:unread_count_do_update)
          .with(@owner, @update_statement)

        @test_feed.set_unread_count(@owner, -1)
      end
    end


    context "explicit max feed size" do
      it "uses the correct max size if the specified count is too big" do
        @update_statement[:update] = {
          :'$set' => {:count => TestUnreadCount::MAX_FEED_SIZE}
        }

        expect(@test_feed).to receive(:unread_count_do_update)
          .with(@owner, @update_statement)

        @test_feed.set_unread_count(@owner, TestUnreadCount::MAX_FEED_SIZE + 1)
      end
    end
  end


  describe "#unread_count_do_update" do
    before(:each) do
      collection_name = "#{@owner.type}.#{TestUnreadCount::FEED_NAME}.unread_count"

      expect(@mongo_db).to receive(:collection)
        .with(collection_name)
        .and_return(@mongo_collection)

      expect(@mongo_collection).to receive(:name)
        .and_return(collection_name)
    end


    context "index constraint violation" do
      it "does not raise an error" do
        expect(@mongo_collection).to receive(:find_and_modify)
          .with(instance_of(Hash))
          .and_raise Mongo::OperationFailure.new("error", TestUnreadCount::MONGO_ERROR_DUPLICATE_KEY)

        @test_feed.set_unread_count(@owner, 10)
      end
    end


    context "other mongo errors" do
      it "raises an error" do
        expect(@mongo_collection).to receive(:find_and_modify)
          .with(instance_of(Hash))
          .and_raise Mongo::OperationFailure.new("error", 99999)

        expect{@test_feed.set_unread_count(@owner, 10)}.to raise_error Mongo::OperationFailure
      end
    end
  end

end
