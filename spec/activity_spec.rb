require 'multi_json'
require 'spec_helper'

describe RealSelf::Stream::Activity do

  def example_activity
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

  def example_activity_without_target_or_relatives
    RealSelf::Stream::Activity.new(
      'sample activity title',
      DateTime.parse('1970-01-01T00:00:00Z'),
      RealSelf::Stream::Objekt.new('dr', 1234),
      'author',
      RealSelf::Stream::Objekt.new('answer', 2345),
      nil,
      nil
    )
  end

  before :each do
    @activity = RealSelf::Stream::Activity.from_json(example_activity.to_s)
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
     (@activity.actor == example_activity.actor).should be_true
     (@activity.actor == example_activity.object).should be_false
    end
  end

  describe "#verb" do
    it "returns the verb" do
      @activity.verb.should eql example_activity.verb
    end
  end

  describe "#objekt" do
    it "returns the object of the activity" do
     (@activity.object == example_activity.object).should be_true
     (@activity.object == example_activity.actor).should be_false
    end
  end

  describe "#target" do
    it "returns the target of the activity" do
     (@activity.target == example_activity.target).should be_true
     (@activity.target == example_activity.actor).should be_false
    end
  end

  describe "#relatives" do
    it "returns the activity relatives collection" do
      @activity.relatives.length.should eql 1
      ((@activity.relatives)[0]).should be_an_instance_of RealSelf::Stream::Objekt
      (@activity.relatives[0] == RealSelf::Stream::Objekt.new('topic', 4567)).should be_true
    end
  end

  describe "#to_h" do
    it "returns a hash representation of the activity" do
      hash = example_activity.to_h
      @activity.to_h.should eql hash

      json = MultiJson.encode(@activity.to_h)
      activity = RealSelf::Stream::Activity.from_json(json)  
      (@activity == activity).should be_true

      # test with activity that is missing target and relations
      hash = example_activity_without_target_or_relatives.to_h
      json = MultiJson.encode(hash)
      activity_2 = RealSelf::Stream::Activity.from_json(json)
      (activity_2 == example_activity_without_target_or_relatives).should be_true
    end
  end

  describe "::from_json" do
    it "creates an activity from a JSON string" do
      json = MultiJson.encode(@activity.to_h)
      activity = RealSelf::Stream::Activity.from_json(json)  
      (@activity == activity).should be_true
    end
  end
end