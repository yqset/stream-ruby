RSpec.configure do |c|
  c.include Digest::Helpers
end

shared_examples "a summary" do |summary_class|

  before :each do
    Digest::Helpers.init(summary_class)
  end

  describe "#new" do
    it "raises an error if instantiated incorrectly" do
      object = RealSelf::Stream::Objekt.new('bogus', 'object')
      expect{summary_class.new(object)}.to raise_error
    end
  end

  describe "::create" do
    it "creates a new summary" do
      object = content_objekt
      summary = RealSelf::Stream::Digest::Summary.create(object)
      expect(summary).to be_an_instance_of(summary_class)
    end

    it "fails to create a summary of unknown type" do
      object = RealSelf::Stream::Objekt.new('bogus', 'object')
      expect{RealSelf::Stream::Summary.create(object)}.to raise_error
    end
  end

  describe "::from_array" do
    it "creates a summary from an array" do
      object = content_objekt
      summary = RealSelf::Stream::Digest::Summary.create(object)
      activities = summary.to_h

      array = [object.to_h, activities]

      summary = RealSelf::Stream::Digest::Summary.from_array(array)
      expect(summary).to be_an_instance_of(summary_class)
      expect(summary.to_array).to eql array
    end
  end

  describe "::from_json" do
    it "creates a summary from an array" do
      object = content_objekt
      summary = RealSelf::Stream::Digest::Summary.create(object)
      json = summary.to_s

      summary2 = RealSelf::Stream::Digest::Summary.from_json(json)
      expect(summary2).to be_an_instance_of(summary_class)
      expect(summary).to eql summary2
    end
  end

end
