require 'spec_helper'

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
      Activity::Helpers.init(1)
      json = MultiJson.encode(example_hash)
      activity = RealSelf::Stream::Activity.from_json(json)
      expect(activity).to be_an_instance_of RealSelf::Stream::ActivityV1
      expect(activity.version).to eql 1
    end

    it "can create a version 2 activity" do
      Activity::Helpers.init(2)
      json = MultiJson.encode(example_hash)
      activity = RealSelf::Stream::Activity.from_json(json)
      expect(activity).to be_an_instance_of RealSelf::Stream::ActivityV2
      expect(activity.version).to eql 2
    end
  end


  describe "::from_hash" do
    it "can create a version 1 activity" do
      Activity::Helpers.init(1)
      activity = RealSelf::Stream::Activity.from_hash(example_hash)
      expect(activity).to be_an_instance_of RealSelf::Stream::ActivityV1
      expect(activity.version).to eql 1
    end

    it "can create a version 2 activity" do
      Activity::Helpers.init(2)
      activity = RealSelf::Stream::Activity.from_hash(example_hash)
      expect(activity).to be_an_instance_of RealSelf::Stream::ActivityV2
      expect(activity.version).to eql 2
    end

    it "raises an error when trying to create an unknown version" do
      Activity::Helpers.init(0)
      expect{RealSelf::Stream::Activity.from_hash(example_hash)}.to raise_error
    end
  end


  describe '#==' do
    it 'compares two activities' do
      activity = Activity::Helpers.init(2)
      other = Activity::Helpers.init(2)

      expect(activity).to eql other

      other = Activity::Helpers.init(1)
      expect(activity).to_not eql other
    end

    it 'compares to nil' do
      activity = Activity::Helpers.init(2)
      expect(activity).to_not eql nil
    end

    it 'compares to other object types' do
      activity = Activity::Helpers.init(2)
      expect(activity).to_not eql RealSelf::Stream::Objekt.new('user', 1234)
      expect(activity).to_not eql 'string'
      expect(activity).to_not eql({:foo => 'bar'})
      expect(activity).to_not eql Exception.new('oops!')
    end
  end


  describe "#hash" do
    it "supports hash key equality" do
      Activity::Helpers.init(2)
      a1 = RealSelf::Stream::Activity.from_hash(example_hash)

      a2 = RealSelf::Stream::Activity.from_hash(example_hash)

      expect(a1.object_id).to_not eql(a2.object_id)

      e = {}
      e[a2] = 123

      expect(e.include?(a1)).to eql(true)
    end
  end


  describe '#content_type' do
    it 'returns the expected content type' do
      expect(RealSelf::Stream::Activity.new.content_type).to eql RealSelf::ContentType::ACTIVITY
    end
  end
end
