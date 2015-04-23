require 'spec_helper'

describe RealSelf::Feed::Redactable do

  class TestRedactable
    FEED_NAME = :test_redactable_feed
    include RealSelf::Feed::Redactable
  end

  before(:each) do
    @mongo_db = double('Mongo::DB')
    @mongo_collections = []

    # build mock collections
    [
      "user.#{TestRedactable::FEED_NAME}",
      "foo.#{(TestRedactable::FEED_NAME)}",
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

    # @owner = RealSelf::Stream::Objekt.new('user', '1234')

    @test_feed = TestRedactable.new
    @test_feed.mongo_db = @mongo_db
  end


  describe "#redact" do
    context "invalid UUID" do
      it "raises an error" do
        expect{@test_feed.redact('bogus-uuid')}
          .to raise_error RealSelf::Feed::FeedError
      end
    end


    context "valid UUID" do
      before(:all) do
        @uuid = '1B28BCEA-A9D5-4421-8D9B-39C7F3E25B2C'
      end


      it "does not redact from non-redactable collections" do
        # first two collections should get called
        2.times do |index|
          expect(@mongo_collections[index]).to receive(:update)
            .with(
              {:'activity.uuid' => @uuid},
              {:'$set' => {:redacted => true}},
              {:upsert => false, :multi => true})
            .and_return({'updatedExisting' => true})
        end

        result = @test_feed.redact(@uuid)

        expect(result.length).to eql 2
        expect(result.include? "user.#{TestRedactable::FEED_NAME}").to eql true
        expect(result.include? "foo.#{TestRedactable::FEED_NAME}").to eql true
      end
    end
  end
end
