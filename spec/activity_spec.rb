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
    RealSelf::Stream::Activity.new(
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
    RealSelf::Stream::Activity.new(
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
    RealSelf::Stream::Activity.new(
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
    RealSelf::Stream::Activity.new(
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
  end

  describe '::from_hash' do
    it 'takes a hash and returns a new instance' do
      @activity.should eql RealSelf::Stream::Activity.from_hash(example_hash)
    end
  end

  describe "#new" do
    it "takes two parameters and returns an Objekt object" do
      @activity.should be_an_instance_of RealSelf::Stream::Activity
    end
  end

  describe "#title" do
    it "returns the correct title" do
      @activity.title.should eql example_activity.title
    end
  end

  describe "#published" do
    it "returns the correct published date" do
      @activity.published.should eql example_activity.published
    end
  end 

  describe "#actor" do
    it "returns the actor" do
      @activity.actor.should eql example_activity.actor
      @activity.actor.should_not eql example_activity.object
    end
  end

  describe "#verb" do
    it "returns the verb" do
      @activity.verb.should eql example_activity.verb
    end
  end

  describe "#objekt" do
    it "returns the object of the activity" do
      @activity.object.should eql example_activity.object
      @activity.object.should_not eql example_activity.actor
    end
  end

  describe "#target" do
    it "returns the target of the activity" do
      @activity.target.should eql example_activity.target
      @activity.target.should_not eql example_activity.actor
    end
  end

  describe "#relatives" do
    it "returns the activity relatives collection" do
      @activity.relatives.length.should eql 1
      @activity.relatives.first.should be_an_instance_of RealSelf::Stream::Objekt
      @activity.relatives.first.should eql RealSelf::Stream::Objekt.new('topic', 4567)
    end
  end

  describe "#uuid" do
    it "returns the UUID of the activity" do
      @activity.uuid.should_not be_nil
      (/^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$/ =~ @activity.uuid).should eql 0
      (@activity.uuid == example_activity.uuid).should be_true
    end

    it "generates a UUID if one is not supplied" do
      activity = example_activity_without_uuid
      (/^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$/ =~ activity.uuid).should eql 0
      activity2 = example_activity_without_uuid
      (activity.uuid == activity2.uuid).should be_false
      (activity == activity2).should be_false
    end
  end

  describe "#prototype" do
    it "returns the prototype of the activity" do
      @activity.prototype.should_not be_nil
      (@activity.prototype == example_activity.prototype).should be_true
    end

    it "generates a prototype if one is not supplied" do
      activity = example_activity_without_prototype      
      (activity.prototype == "#{activity.actor.type}.#{activity.verb}.#{activity.object.type}").should be_true
    end
  end

  describe "#to_h" do
    it "returns a hash representation of the activity" do
      hash = example_activity.to_h
      @activity.to_h.should eql hash

      json = MultiJson.encode(@activity.to_h)
      activity = RealSelf::Stream::Activity.from_json(json)
      @activity.should eql activity

      # test with activity that is missing target and relations
      hash = example_activity_without_target_or_relatives.to_h
      json = MultiJson.encode(hash)
      activity_2 = RealSelf::Stream::Activity.from_json(json)
      activity_2.should eql example_activity_without_target_or_relatives
    end
  end

  describe "::from_json" do
    it "creates an activity from a JSON string" do
      activity = RealSelf::Stream::Activity.from_json(MultiJson::encode(example_hash))
      @activity.should eql activity
    end
  end
end