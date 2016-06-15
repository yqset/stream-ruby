require 'spec_helper'
require 'mongo'

shared_examples RealSelf::Feed::State::Bookmarkable do |feed|
  before :all do
    @feed.mongo_db   = IntegrationHelper.get_mongo
    @feed.ensure_index :user, background: false
  end


  before :each do
    @owner = RealSelf::Stream::Objekt.new('user', Random::rand(1000..99999))
  end


  describe '#bookmark' do
    it 'bookmark/set a position with valid BSON::ObjectId' do
      position = BSON::ObjectId.from_time(Time.now)
      set_pos = @feed.set_bookmark(@owner, position)
      get_pos = @feed.get_bookmark(@owner)

      expect(set_pos).to eql get_pos
      expect(position).to eql set_pos
    end

    it 'will not accept illegal BSON::ObjectId' do
      position = "It's a string!"
      expect{ @feed.set_bookmark(@owner, position) }.to raise_error(RealSelf::Feed::FeedError)
    end
  end


  describe '#ensure_index' do
    it 'creates the correct indexes' do
      collection = @feed.send(:state_collection, @owner.type)
      indexes    = collection.indexes.to_a

      expect(indexes[0][:name]).to eql "_id_"

      expect(indexes[1][:name]).to    eql "owner_id_-1"
      expect(indexes[1][:key]).to     eql({'owner_id' => Mongo::Index::DESCENDING})
      expect(indexes[1][:unique]).to  eql true
    end
  end
end
