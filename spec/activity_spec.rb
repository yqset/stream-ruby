require 'multi_json'
require 'spec_helper'

describe RealSelf::Stream::Activity do

  def example_hash
    {
      :title => "sample activity title",
      :published => "1970-01-01T00:00:00+00:00",
      :actor => {:type => "dr", :id => "1234"},
      :verb => "author",
      :object => {:type => "answer", :id => "2345"},
      :relatives => [{:type => "topic", :id => "4567"}],
      :uuid => "f364c40c-6e91-4064-a825-faae79c10254",
      :target => {:type => "question", :id => "3456"},
      :prototype => "explicit.prototype.value"
    }
  end

  def example_activity
    RealSelf::Stream::Activity.create(1,
      'sample activity title',
      DateTime.parse('1970-01-01T00:00:00Z'),
      RealSelf::Stream::Objekt.new('dr', 1234),
      'author',
      RealSelf::Stream::Objekt.new('answer', 2345),
      RealSelf::Stream::Objekt.new('question', 3456),
      [RealSelf::Stream::Objekt.new('topic', 4567)],
      "f364c40c-6e91-4064-a825-faae79c10254",
      "explicit.prototype.value"
    )
  end

  def example_activity_without_uuid
    RealSelf::Stream::Activity.create(1,
      'sample activity title',
      DateTime.parse('1970-01-01T00:00:00Z'),
      RealSelf::Stream::Objekt.new('dr', 1234),
      'author',
      RealSelf::Stream::Objekt.new('answer', 2345),
      RealSelf::Stream::Objekt.new('question', 3456),
      [RealSelf::Stream::Objekt.new('topic', 4567)]
    )
  end

  def example_activity_without_prototype
    RealSelf::Stream::Activity.create(1,
      'sample activity title',
      DateTime.parse('1970-01-01T00:00:00Z'),
      RealSelf::Stream::Objekt.new('dr', 1234),
      'author',
      RealSelf::Stream::Objekt.new('answer', 2345),
      RealSelf::Stream::Objekt.new('question', 3456),
      [RealSelf::Stream::Objekt.new('topic', 4567)],
      "f364c40c-6e91-4064-a825-faae79c10254"
    )
  end  

  def example_activity_without_target_or_relatives
    RealSelf::Stream::Activity.create(1,
      'sample activity title',
      DateTime.parse('1970-01-01T00:00:00Z'),
      RealSelf::Stream::Objekt.new('dr', 1234),
      'author',
      RealSelf::Stream::Objekt.new('answer', 2345),
      nil,
      nil,
      "f364c40c-6e91-4064-a825-faae79c10254"
    )
  end

  before :each do
    @activity = RealSelf::Stream::Activity.from_json(example_activity.to_s)
    @activity.to_version(1)
  end

  describe '::from_hash' do
    it 'takes a hash and returns a new instance' do
      expect(@activity).to eql RealSelf::Stream::Activity.from_hash(example_hash)
    end
  end

  describe "#new" do
    it "takes two parameters and returns an Objekt object" do
      expect(@activity).to be_an_instance_of RealSelf::Stream::ActivityV1
    end
  end

  describe "#title" do
    it "returns the correct title" do
      expect(@activity.title).to eql example_activity.title
    end
  end

  describe "#published" do
    it "returns the correct published date" do
      expect(@activity.published).to eql example_activity.published
    end
  end 

  describe "#actor" do
    it "returns the actor" do
      expect(@activity.actor).to eql example_activity.actor
      expect(@activity.actor).to_not eql example_activity.object
    end
  end

  describe "#verb" do
    it "returns the verb" do
      expect(@activity.verb).to eql example_activity.verb
    end
  end

  describe "#objekt" do
    it "returns the object of the activity" do
      expect(@activity.object).to eql example_activity.object
      expect(@activity.object).to_not eql example_activity.actor
    end
  end

  describe "#target" do
    it "returns the target of the activity" do
      expect(@activity.target).to eql example_activity.target
      expect(@activity.target).to_not eql example_activity.actor
    end
  end

  describe "#relatives" do
    it "returns the activity relatives collection" do
      expect(@activity.relatives.length).to eql 1
      expect(@activity.relatives.first).to be_an_instance_of RealSelf::Stream::Objekt
      expect(@activity.relatives.first).to eql RealSelf::Stream::Objekt.new('topic', 4567)
    end
  end

  describe "#uuid" do
    it "returns the UUID of the activity" do
      expect(@activity.uuid).to_not be_nil
      expect(/^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$/ =~ @activity.uuid).to eql 0
      expect(@activity.uuid).to eql example_activity.uuid
    end

    it "generates a UUID if one is not supplied" do
      activity = example_activity_without_uuid
      expect(/^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$/ =~ activity.uuid).to eql 0
      activity2 = example_activity_without_uuid
      expect(activity.uuid).to_not eql activity2.uuid
      expect(activity).to_not eql activity2
    end
  end

  describe "#prototype" do
    it "returns the prototype of the activity" do
      expect(@activity.prototype).to_not be_nil
      expect(@activity.prototype).to eql example_activity.prototype
    end

    it "generates a prototype if one is not supplied" do
      activity = example_activity_without_prototype
      expect(activity.prototype).to eql "#{activity.actor.type}.#{activity.verb}.#{activity.object.type}"  
    end
  end

  describe "#to_h" do
    it "returns a hash representation of the activity" do
      hash = example_activity.to_h
      expect(@activity.to_h).to eql hash

      json = MultiJson.encode(@activity.to_h)
      activity = RealSelf::Stream::Activity.from_json(json)
      expect(@activity).to eql activity

      # test with activity that is missing target and relations
      hash = example_activity_without_target_or_relatives.to_h
      json = MultiJson.encode(hash)
      activity_2 = RealSelf::Stream::Activity.from_json(json)
      expect(activity_2).to eql example_activity_without_target_or_relatives
    end
  end

  describe "::from_json" do
    it "creates an activity from a JSON string" do
      activity = RealSelf::Stream::Activity.from_json(MultiJson::encode(example_hash))
      expect(@activity).to eql activity
    end
  end

  describe "#to_version" do
    it "returns itself when the same version is requested" do
      expect(@activity.to_version(1)).to eql @activity
    end

    it "raises an error when a conversion is not possible" do
      expect{@activity.to_version(2)}.to raise_error
    end
  end
end