require_relative '../../helpers'
include Helpers

describe RealSelf::Stream::ActivityV2, "with activity type v2" do

  describe "#new" do
    it "creates an activity object" do
      activity = RealSelf::Stream::ActivityV2.new(
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

      expect(activity).to be_an_instance_of RealSelf::Stream::ActivityV2
    end

    it "fails to create an activity object from invalid params" do
      expect{RealSelf::Stream::ActivityV2.new(
        'sample activity title',
        DateTime.parse('1970-01-01T00:00:00Z'),
        RealSelf::Stream::Objekt.new('dr', 1234),
        'author',
        RealSelf::Stream::Objekt.new('answer', 2345),
        RealSelf::Stream::Objekt.new('question', 3456),
        [RealSelf::Stream::Objekt.new('topic', 4567)],  #invalid
        "f364c40c-6e91-4064-a825-faae79c10254",
        "explicit.prototype.value"
      )}.to raise_error
    end
  end

  describe "version checks" do
    it "returns the extensions collection" do
      Helpers.init(2)
      activity = RealSelf::Stream::ActivityV2.from_json(example_activity.to_s)
      expect(activity.extensions[:topic]).to be_an_instance_of RealSelf::Stream::Objekt
      expect(activity.extensions[:topic]).to eql RealSelf::Stream::Objekt.new('topic', 4567)
    end

    it "does not have a relatives collection" do
      Helpers.init(2)
      activity = RealSelf::Stream::ActivityV2.from_json(example_activity.to_s)
      expect(activity).to_not respond_to :relatives
    end

    it "raises an error when trying to convert to an unknown version" do
      Helpers.init(2)
      activity = RealSelf::Stream::ActivityV2.from_json(example_activity.to_s)
      expect{activity.to_version(3)}.to raise_error
    end

    it "raises an error when trying to create an unknown version" do
      Helpers.init(0)
      expect{RealSelf::Stream::ActivityV2.from_hash(example_hash)}.to raise_error
    end

    it "converts extensions to relatives when converting to a v1 activity" do
      activity = RealSelf::Stream::ActivityV2.new(
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

      activity_v1 = activity.to_version(1)
      expect(activity_v1.relatives).to_not eql nil
      expect(activity_v1.relatives.length).to eql 1
    end
  end

  it_should_behave_like "an activity", 2
end
