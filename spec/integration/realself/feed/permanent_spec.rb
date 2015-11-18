require 'spec_helper'

describe RealSelf::Feed::Permanent do
  include Helpers

  class TestPermanent < RealSelf::Feed::Permanent
    FEED_NAME = :permanent_integrtion_test.freeze
    include RealSelf::Feed::Redactable
    include RealSelf::Feed::UnreadCountable
  end


  before :all do
    @feed           = TestPermanent.new
    @feed.mongo_db  = IntegrationHelper.get_mongo
    TestPermanent.ensure_index :user, background: false, mongo: @feed.mongo_db
  end

  it_should_behave_like '#insertable', @feed
  it_should_behave_like RealSelf::Feed::Getable, @feed
  it_should_behave_like RealSelf::Feed::Redactable, @feed
  it_should_behave_like RealSelf::Feed::UnreadCountable, @feed


  before :each do
    @owner = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
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


      expect(collection.indexes.to_a.size).to eql 4 # including 'redactable' index

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
end
