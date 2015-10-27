require_relative 'activity_shared_examples'
require_relative 'followed_activity_shared_examples'

include Helpers

describe RealSelf::Stream::ActivityV1, "with activity type v1" do

  describe "#new" do
    it "creates an activity object" do
      activity = RealSelf::Stream::ActivityV1.new(
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

      expect(activity).to be_an_instance_of RealSelf::Stream::ActivityV1
    end

    it "fails to create an activity object from invalid params" do
      expect{RealSelf::Stream::ActivityV1.new(
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('dr', 1234),
        'author',
        RealSelf::Stream::Objekt.new('answer', 2345),
        RealSelf::Stream::Objekt.new('question', 3456),
        {:topic => RealSelf::Stream::Objekt.new('topic', 4567)},  #invalid
        "f364c40c-6e91-4064-a825-faae79c10254",
        "explicit.prototype.value"
      )}.to raise_error
    end
  end

  describe "version checks" do
    it "returns the relatives collection" do
      Helpers.init(1)
      activity = RealSelf::Stream::ActivityV1.from_json(example_activity.to_s)
      expect(activity.relatives.first).to be_an_instance_of RealSelf::Stream::Objekt
      expect(activity.relatives.first).to eql RealSelf::Stream::Objekt.new('topic', 4567)
    end

    it "does not have an extensions collection" do
      Helpers.init(1)
      activity = RealSelf::Stream::ActivityV1.from_json(example_activity.to_s)
      expect(activity).to_not respond_to :extensions
    end

    it "raises an error when trying to convert to an unknown version" do
      Helpers.init(1)
      activity = RealSelf::Stream::ActivityV1.from_json(example_activity.to_s)
      expect{activity.to_version(2)}.to raise_error
    end

    it "raises an error when trying to create an unknown version" do
      Helpers.init(0)
      expect{RealSelf::Stream::ActivityV1.from_hash(example_hash)}.to raise_error
    end
  end

  it_should_behave_like "an activity", 1
end
