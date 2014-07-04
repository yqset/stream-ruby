require 'multi_json'
require 'spec_helper'
require 'activity_shared_examples'

describe RealSelf::Stream::Activity do
  describe "::create" do
    it "can create a version 1 activity" do
      activity = RealSelf::Stream::Activity.create(1,
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

      expect(activity.version).to eql 1
      expect(activity).to be_an_instance_of RealSelf::Stream::ActivityV1
    end

    it "can create a version 2 activity" do
      activity = RealSelf::Stream::Activity.create(2,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('dr', 1234),
        'author',
        RealSelf::Stream::Objekt.new('answer', 2345),
        RealSelf::Stream::Objekt.new('question', 3456),
        {:topic => RealSelf::Stream::Objekt.new('topic', 4567)},
        "f364c40c-6e91-4064-a825-faae79c10254",
        "explicit.prototype.value"
      )  

      expect(activity.version).to eql 2
      expect(activity).to be_an_instance_of RealSelf::Stream::ActivityV2          
    end

    it "fails to create an unknown activity version" do
      expect{RealSelf::Stream::Activity.create(0,
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('dr', 1234),
        'author',
        RealSelf::Stream::Objekt.new('answer', 2345),
        RealSelf::Stream::Objekt.new('question', 3456),
        [RealSelf::Stream::Objekt.new('topic', 4567)],
        "f364c40c-6e91-4064-a825-faae79c10254",
        "explicit.prototype.value"
      )}.to raise_error
    end    
  end

  describe "::from_json" do
    it "can create a version 1 activity" do
      Helpers.init(1)
      json = MultiJson.encode(example_hash)
      activity = RealSelf::Stream::Activity.from_json(json)
      expect(activity).to be_an_instance_of RealSelf::Stream::ActivityV1
      expect(activity.version).to eql 1
    end

    it "can create a version 2 activity" do
      Helpers.init(2)
      json = MultiJson.encode(example_hash)
      activity = RealSelf::Stream::Activity.from_json(json)
      expect(activity).to be_an_instance_of RealSelf::Stream::ActivityV2
      expect(activity.version).to eql 2
    end    
  end

  describe "::from_hash" do
    it "can create a version 1 activity" do
      Helpers.init(1)
      activity = RealSelf::Stream::Activity.from_hash(example_hash)
      expect(activity).to be_an_instance_of RealSelf::Stream::ActivityV1
      expect(activity.version).to eql 1
    end

    it "can create a version 2 activity" do
      Helpers.init(2)
      activity = RealSelf::Stream::Activity.from_hash(example_hash)
      expect(activity).to be_an_instance_of RealSelf::Stream::ActivityV2
      expect(activity.version).to eql 2
    end     
  end
end