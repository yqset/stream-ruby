require 'spec_helper'


describe RealSelf::Graph::Follow do
  before :all do
    RealSelf::Graph::Follow.configure IntegrationHelper.get_mongo
    RealSelf::Graph::Follow.ensure_index :user, false
  end


  before :each do
    @actor  = RealSelf::Stream::Objekt.new(:user, Random::rand(1000..99999))
    @object = RealSelf::Stream::Objekt.new(:thing, Random::rand(1000..99999))
  end

  describe '#count_followers_of' do
    it 'returns the count of followers' do
      expect(RealSelf::Graph::Follow.count_followers_of(
        :user,
        @object)).to eql 0

      RealSelf::Graph::Follow.follow @actor, @object

      expect(RealSelf::Graph::Follow.count_followers_of(
        :user,
        @object)).to eql 1

      actor2  = RealSelf::Stream::Objekt.new(:user, Random::rand(1000..99999))

      RealSelf::Graph::Follow.follow actor2, @object

      expect(RealSelf::Graph::Follow.count_followers_of(
        :user,
        @object)).to eql 2
    end
  end


  describe '#ensure_index' do
    it 'creates the correct indexes' do
      collection  = RealSelf::Graph::Follow.send(:get_collection, @actor.type)
      indexes     = collection.indexes.to_a

      result = indexes.map do |index|
        case index[:name]
        when "_id_"
          index[:name]
        when 'actor.id_-1_object_-1'
          index[:name]
        when 'object_-1'
          index[:name]
        end
      end.compact

      expect(result.size).to eql 3
    end
  end


  describe '#is_following' do
    it 'tests if an actor is following one or more objects' do
      RealSelf::Graph::Follow.follow @actor, @object
      object2 = RealSelf::Stream::Objekt.new(:thing, Random::rand(1000..99999))

      result = RealSelf::Graph::Follow.is_following(@actor, [@object, object2])

      expect(result.include?(@object)).to eql true
      expect(result.include?(object2)).to eql false

      RealSelf::Graph::Follow.follow @actor, object2

      result = RealSelf::Graph::Follow.is_following(@actor, [@object, object2])

      expect(result.include?(@object)).to eql true
      expect(result.include?(object2)).to eql true
    end


    it 'yields results one at a time' do
      RealSelf::Graph::Follow.follow @actor, @object
      object2 = RealSelf::Stream::Objekt.new(:thing, Random::rand(1000..99999))
      RealSelf::Graph::Follow.follow @actor, object2

      RealSelf::Graph::Follow.is_following(@actor, [@object, object2]) do |item|
        expect([@object, object2].include?(item)).to eql true
      end
    end
  end


  describe '#follow' do
    it 'creates follow relationships' do
      expect(RealSelf::Graph::Follow.follow(@actor, @object)).to eql true

      expect(RealSelf::Graph::Follow.count_followers_of(
        :user,
        @object)).to eql 1

      expect(RealSelf::Graph::Follow.followers_of(
        :user,
        @object)).to eql ({@actor => [@object]})
    end


    it 'creates follow relationships idempotently' do
      expect(RealSelf::Graph::Follow.follow(@actor, @object)).to eql true
      expect(RealSelf::Graph::Follow.follow(@actor, @object)).to eql true

      expect(RealSelf::Graph::Follow.count_followers_of(
        :user,
        @object)).to eql 1

      expect(RealSelf::Graph::Follow.followers_of(
        :user,
        @object)).to eql ({@actor => [@object]})
    end
  end


  describe '#followed_by' do
    it 'returns a list of objects that the actor is following' do
      RealSelf::Graph::Follow.follow @actor, @object

      object2 = RealSelf::Stream::Objekt.new(:thing, Random::rand(1000..99999))
      RealSelf::Graph::Follow.follow @actor, object2

      object3 = RealSelf::Stream::Objekt.new(:thing, Random::rand(1000..99999))

      results = RealSelf::Graph::Follow.followed_by @actor

      expect(results.include?(@object)).to eql true
      expect(results.include?(object2)).to eql true
      expect(results.include?(object3)).to eql false
    end


    it 'yields results one at a time' do
      RealSelf::Graph::Follow.follow @actor, @object

      object2 = RealSelf::Stream::Objekt.new(:thing, Random::rand(1000..99999))
      RealSelf::Graph::Follow.follow @actor, object2

      RealSelf::Graph::Follow.followed_by(@actor) do |item|
        expect([@object, object2].include?(item)).to eql true
      end
    end
  end


  describe '#followers_of' do
    before :each do
      @actor    = RealSelf::Stream::Objekt.new(:user, 1)
      @actor2   = RealSelf::Stream::Objekt.new(:user, 2)
      @actor3   = RealSelf::Stream::Objekt.new(:user, 3)
      @object2  = RealSelf::Stream::Objekt.new(:thing, Random::rand(1000..99999))
    end


    it 'returns a list of actors following an object or objects' do
      RealSelf::Graph::Follow.follow @actor, @object

      results = RealSelf::Graph::Follow.followers_of @actor.type, @object

      expect(results.include?(@actor)).to eql true
      expect(results.count).to eql 1


      RealSelf::Graph::Follow.follow @actor2, @object

      results = RealSelf::Graph::Follow.followers_of @actor.type, @object

      expect(results.include?(@actor)).to eql true
      expect(results.include?(@actor2)).to eql true
      expect(results.include?(@actor3)).to eql false
      expect(results.count).to eql 2


      RealSelf::Graph::Follow.follow @actor2, @object2
      RealSelf::Graph::Follow.follow @actor3, @object2

      results = RealSelf::Graph::Follow.followers_of @actor.type, [@object, @object2]

      expect(results[@actor]).to eql ([@object])
      expect(results[@actor2].length).to eql 2
      expect(results[@actor2].include?(@object)).to eql true
      expect(results[@actor2].include?(@object2)).to eql true
      expect(results[@actor3]).to eql ([@object2])
    end


    it 'yields results one at a time' do
      RealSelf::Graph::Follow.follow @actor, @object
      RealSelf::Graph::Follow.follow @actor, @object2
      RealSelf::Graph::Follow.follow @actor2, @object
      RealSelf::Graph::Follow.follow @actor3, @object2


      expect{ |b| RealSelf::Graph::Follow.followers_of(:user, @object, &b)}
        .to yield_successive_args([@actor, [@object]], [@actor2, [@object]])

      expect{ |b| RealSelf::Graph::Follow.followers_of(:user, [@object, @object2], &b)}
        .to yield_successive_args(
          [@actor, [@object, @object2]],
          [@actor2, [@object]],
          [@actor3, [@object2]])
    end
  end


  describe '#unfollow' do
    it 'removes follow relationships' do
      RealSelf::Graph::Follow.follow @actor, @object

      object2 = RealSelf::Stream::Objekt.new(:thing, Random::rand(1000..99999))
      RealSelf::Graph::Follow.follow @actor, object2

      expect(RealSelf::Graph::Follow.is_following(@actor, @object).include?(@object)).to eql true
      expect(RealSelf::Graph::Follow.is_following(@actor, object2).include?(object2)).to eql true

      expect(RealSelf::Graph::Follow.unfollow(@actor, @object)).to eql true

      expect(RealSelf::Graph::Follow.is_following(@actor, @object).include?(@object)).to eql false
      expect(RealSelf::Graph::Follow.is_following(@actor, object2).include?(object2)).to eql true


      expect(RealSelf::Graph::Follow.unfollow(@actor, object2)).to eql true

      expect(RealSelf::Graph::Follow.is_following(@actor, @object).include?(@object)).to eql false
      expect(RealSelf::Graph::Follow.is_following(@actor, object2).include?(object2)).to eql false

      expect(RealSelf::Graph::Follow.unfollow(@actor, @object)).to eql false
    end
  end
end
