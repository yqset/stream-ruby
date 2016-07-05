require 'spec_helper'

shared_examples RealSelf::Feed::Redactable do |feed|
  before :all do
    @feed.mongo_db   = IntegrationHelper.get_mongo
    @feed.ensure_index :user, background: false
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
      activity  = Helpers.user_create_thing_activity
      activity2 = Helpers.user_update_thing_activity

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

  describe '#redact_by_activity' do
    context 'when unpublished content exist in feed' do
      it 'should redact activity' do
        owner     = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
        owner2    = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
        activity  = Helpers.user_create_thing_activity
        activity2 = Helpers.user_update_thing_activity
        unpub_activity = Helpers.user_unpublish_thing_activity(1234, activity.object.id)
        redaction_query = {:'activity.object' => activity.object.to_h}
        unpub_activity2 = Helpers.user_unpublish_thing_activity(1234, activity2.object.id)
        redaction_query2 = {'activity.object' => activity2.object.to_h}

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

        expect(@feed.redact_by_activity(:user, redaction_query)).to eql 2

        result = @feed.get owner
        expect(result[:count]).to eql 1

        result =  @feed.get owner2
        expect(result[:count]).to eql 1

        expect(@feed.redact_by_activity(:user, redaction_query2)).to eql 2

        result = @feed.get owner
        expect(result[:count]).to eql 0

        result =  @feed.get owner2
        expect(result[:count]).to eql 0

      end

      context 'when query returns more than 1 unique uuid' do
        it 'should error' do
          # same object, different activity
          owner     = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
          activity  = Helpers.user_create_thing_activity(Random::rand(1000..9999), 123456)
          activity2 = Helpers.user_update_thing_activity(Random::rand(1000..9999), 123456)

          sa        = RealSelf::Stream::StreamActivity.new(
            owner,
            activity,
            [owner])

          sa2       = RealSelf::Stream::StreamActivity.new(
            owner,
            activity2,
            [owner])

          @feed.insert(owner, sa)
          @feed.insert(owner, sa2)

          redaction_query = {:'activity.object' => activity.object.to_h}
          expect{@feed.redact_by_activity(:user, redaction_query)}
            .to raise_error(RealSelf::Feed::FeedError, /query/)

          # narrows down the query to 1 unique uuid
          narrowed_query = {:'activity.object' => activity.object.to_h,
                            :'activity.prototype' => 'user.update.thing'}
          expect(@feed.redact_by_activity(:user, narrowed_query)).to eql 1
          expect(@feed.redact_by_activity(:user, redaction_query)).to eql 1
        end
      end
    end

    context 'when unpublished content does not exist in feed' do
      it 'does nothing' do
        owner     = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
        owner2    = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
        activity  = Helpers.user_create_thing_activity
        unpub_activity = Helpers.user_unpublish_thing_activity(1234, "0") 
        redaction_query = {"'activity.object'" => unpub_activity.object.to_h}

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

        result = @feed.get owner
        expect(result[:count]).to eql 1

        result =  @feed.get owner2
        expect(result[:count]).to eql 1

        expect(@feed.redact_by_activity(:user, redaction_query)).to eql 0

        result = @feed.get owner
        expect(result[:count]).to eql 1

        result = @feed.get owner2
        expect(result[:count]).to eql 1

      end
    end

    context 'when query input is not a hash' do
      it 'should raise FeedError' do
        expect{@feed.redact_by_activity(:user, "its a string!")}
          .to raise_error(RealSelf::Feed::FeedError, /Invalid/)
      end
    end

    context 'when query input is empty hash' do
      it 'should do nothing' do
        expect{@feed.redact_by_activity(:user, {})}
          .to raise_error(RealSelf::Feed::FeedError, /query/)
      end
    end
  end

  describe '#redact_by_id' do
    it 'should redact item' do
      owner     = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
      activity  = Helpers.user_create_thing_activity
      sa        = RealSelf::Stream::StreamActivity.new(
        owner,
        activity,
        [owner])

      @feed.insert(owner, sa)

      result = @feed.get(owner)
      expect(result[:count]).to eql 1

      id = result[:stream_items][0][:id]
      expect(@feed.redact_by_id(:user, id)).to eql 1

      expect(@feed.get(owner)[:count]).to eql 0
    end

    it 'should only redact 1 item' do
      owner     = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
      activity  = Helpers.user_create_thing_activity
      activity2 = Helpers.user_create_thing_activity

      sa        = RealSelf::Stream::StreamActivity.new(
        owner,
        activity,
        [owner])

      sa2       = RealSelf::Stream::StreamActivity.new(
        owner,
        activity2,
        [owner])

      @feed.insert(owner, sa)
      @feed.insert(owner, sa2)

      result = @feed.get(owner)
      expect(result[:count]).to eql 2

      id = result[:stream_items][0][:id]

      expect(@feed.redact_by_id(:user, id)).to eql 1

      result2 = @feed.get(owner)
      expect(result2[:count]).to eql 1

      # make sure the other item is not redacted
      expect(result2[:stream_items][0][:id]).not_to eql id
    end

    context 'when feed is empty' do
      it 'does nothing and returns 0' do
        owner     = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))

        expect(@feed.get(owner)[:count]).to eql 0

        id = BSON::ObjectId.from_time(Time.now)
        expect(@feed.redact_by_id(:user, id)).to eql 0
      end
    end

    context 'when id passed is illegal' do
      it 'should raise FeedError' do
        expect{@feed.redact_by_id(:user, "not a legit bson object string")}
          .to raise_error(RealSelf::Feed::FeedError, /Invalid/)
      end
    end
  end
end
