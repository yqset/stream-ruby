require 'spec_helper'

describe RealSelf::Feed::Permanent do
  include Helpers

  class TestRollable < RealSelf::Feed::Permanent
    FEED_NAME = :rollable_permanent_integration_test.freeze
    include RealSelf::Feed::Rollable
    include RealSelf::Feed::UnreadCountable
  end


  before :all do
    @feed           = TestRollable.new
    @feed.mongo_db  = IntegrationHelper.get_mongo
    @feed.ensure_index :user, background: false
  end

  it_should_behave_like '#insertable', @feed
  it_should_behave_like RealSelf::Feed::Getable, @feed
  it_should_behave_like RealSelf::Feed::UnreadCountable, @feed


  before :each do
    @owner  = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
    @owner2 = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
  end


  describe '#ensure_index' do
    it 'creates the correct indexes' do
      collection = @feed.send(:get_collection, @owner.type)
      indexes    = collection.indexes.to_a

      result = indexes.map do |index|
        case index[:name]
        when "_id_"
          index[:name]
        when "object.id_-1__id_-1"
          index[:name]
        when "activity.uuid_-1_object.id_-1"
          index[:name]
        end
      end.compact


      expect(collection.indexes.to_a.size).to eql 6 # include 'permanent' index

      expect(indexes[0][:name]).to eql "_id_"

      expect(indexes[1][:name]).to  eql "object.id_-1__id_-1"
      expect(indexes[1][:key]).to   eql({
        'object.id' => Mongo::Index::DESCENDING,
        '_id'       => Mongo::Index::DESCENDING})
      expect(indexes[1][:unique]).to  eql true

      expect(indexes[2][:name]).to  eql "activity.uuid_-1_object.id_-1"
      expect(indexes[2][:key]).to   eql({
        'activity.uuid'  => Mongo::Index::DESCENDING,
        'object.id'      => Mongo::Index::DESCENDING})
      expect(indexes[2][:unique]).to  eql true
    end
  end

  describe '#insert_or_rollup' do
    context "object based roll up" do
      before :each do
        @interested_user_id = Random::rand(1000..99999)
        @interested_user = RealSelf::Stream::Objekt.new('user', @interested_user_id)
        @match_on_actor = {:'activity.actor' => @interested_user.to_h}
        @keys = ['object'] # roll up on object
        @owner_1  = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
        @owner_2 = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
        activity  = Helpers.user_create_thing_activity(@interested_user_id)
        activity2 = Helpers.user_update_thing_activity
        [@owner_1, @owner_2].each { |owner|
          sa = RealSelf::Stream::StreamActivity.new(
            owner,
            activity,
            [activity.actor])
            sa2 = RealSelf::Stream::StreamActivity.new(
              owner,
              activity2,
              [activity2.actor])

              @feed.insert(owner, sa)
              @feed.insert(owner, sa2)
        }
      end

      it 'should do normal insert if there is no matching activity' do
        activity = Helpers.user_create_thing_activity
        sa = RealSelf::Stream::StreamActivity.new(
          @owner_1,
          activity,
          [activity.actor])

          before_size = @feed.get(@owner_1, 10)[:count]
          @feed.insert(@owner_1, sa)
          expect(@feed.get(@owner_1,10)[:count]).to eql before_size + 1
      end

      it 'should not increase count when rolling up' do
        activity = Helpers.user_create_thing_activity(@interested_user_id)
        sa = RealSelf::Stream::StreamActivity.new(
          @owner_1,
          activity,
          [activity.actor])

          before_size = @feed.get(@owner_1, 10)[:count]
          @feed.insert_or_rollup(@owner_1, sa, @match_on_actor, @keys)
          expect(@feed.get(@owner_1,10)[:count]).to eql before_size
      end

      it 'should roll up when there is a matching activity' do
        activity = Helpers.user_create_thing_activity(@interested_user_id)
        sa = RealSelf::Stream::StreamActivity.new(
          @owner_1,
          activity,
          [activity.actor])

          @feed.insert_or_rollup(@owner_1, sa, @match_on_actor, @keys)
          # query for rolled up activity
          result = @feed.get(@owner_1, 10, nil, nil, @match_on_actor)

          expect(result[:stream_items].size).to eql 1
          item = result[:stream_items][0]
          expect(item[:roll_up].size).to eql 1
          expect(item[:activity][:uuid]).to eql activity.uuid
      end

      it 'should handle multiple roll up' do
        rolled_up_ids = []
        userid = Random::rand(1000..99999)
        user_to_match = RealSelf::Stream::Objekt.new('user', userid)
        owner  = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
        5.times do
          activity = Helpers.user_create_thing_activity(userid)
          sa = RealSelf::Stream::StreamActivity.new(
            owner,
            activity,
            [activity.actor])

            @feed.insert_or_rollup(owner, sa, {:'activity.actor' => user_to_match.to_h}, @keys)
            # convert symbol keys to string keys
            rolled_up_ids << activity.object.to_h.map { |k,v| [k.to_s, v] }.to_h
        end

        result = @feed.get(owner, 10)
        expect(result[:count]).to eql 1

        item = result[:stream_items][0]
        expect(item['activity']['object']).to eql rolled_up_ids[4]
        expect(item['roll_up']).to eql rolled_up_ids.first(4)
      end
    end


    context "actor based roll up" do
      before :each do
        @interested_thing_id = Random::rand(1000..99999)
        @interested_thing = RealSelf::Stream::Objekt.new('thing', @interested_thing_id)
        @match_on_object = {:'activity.object' => @interested_thing.to_h}
        @keys = ['actor'] # roll up on object
        @owner_1  = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
        @owner_2 = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
        activity  = Helpers.user_create_thing_activity(Random::rand(1000..99999), @interested_thing_id)
        activity2 = Helpers.user_update_thing_activity
        [@owner_1, @owner_2].each { |owner|
          sa = RealSelf::Stream::StreamActivity.new(
            owner,
            activity,
            [activity.actor])
          sa2 = RealSelf::Stream::StreamActivity.new(
            owner,
            activity2,
            [activity2.actor])

          @feed.insert(owner, sa)
          @feed.insert(owner, sa2)
        }
      end

      it 'should do normal insert if there is no matching activity' do
        activity = Helpers.user_create_thing_activity
        sa = RealSelf::Stream::StreamActivity.new(
          @owner_1,
          activity,
          [activity.actor])

        before_size = @feed.get(@owner_1, 10)[:count]
        @feed.insert(@owner_1, sa)
        expect(@feed.get(@owner_1,10)[:count]).to eql before_size + 1
      end

      it 'should not increase count when rolling up' do
        activity = Helpers.user_create_thing_activity(Random::rand(1000..99999), @interested_thing_id)
        sa = RealSelf::Stream::StreamActivity.new(
          @owner_1,
          activity,
          [activity.actor])

        before_size = @feed.get(@owner_1, 10)[:count]
        @feed.insert_or_rollup(@owner_1, sa, @match_on_object, @keys)
        expect(@feed.get(@owner_1,10)[:count]).to eql before_size
      end

      it 'should roll up when there is a matching activity' do
        activity = Helpers.user_create_thing_activity(Random::rand(1000..99999), @interested_thing_id)
        sa = RealSelf::Stream::StreamActivity.new(
          @owner_1,
          activity,
          [activity.actor])

        @feed.insert_or_rollup(@owner_1, sa, @match_on_object, @keys)
        # query for rolled up activity
        result = @feed.get(@owner_1, 10, nil, nil, @match_on_object)

        expect(result[:stream_items].size).to eql 1
        item = result[:stream_items][0]
        expect(item[:roll_up].size).to eql 1
        expect(item[:activity][:uuid]).to eql activity.uuid
      end

      it 'should handle multiple roll up' do
        rolled_up_ids = []
        thing_id = Random::rand(1000..99999)
        thing_to_match = RealSelf::Stream::Objekt.new('thing', thing_id)
        owner  = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
        5.times do
          activity = Helpers.user_create_thing_activity(Random::rand(1000..99999) ,thing_id)
          sa = RealSelf::Stream::StreamActivity.new(
            owner,
            activity,
            [activity.object])

          @feed.insert_or_rollup(owner, sa, {:'activity.object' => thing_to_match.to_h}, @keys)
          # convert symbol keys to string keys
          rolled_up_ids << activity.actor.to_h.map { |k,v| [k.to_s, v] }.to_h
        end

        result = @feed.get(owner, 10)
        expect(result[:count]).to eql 1

        item = result[:stream_items][0]
        expect(item['activity']['actor']).to eql rolled_up_ids[4]
        expect(item['roll_up']).to eql rolled_up_ids.first(4)
      end
    end
  end
end
