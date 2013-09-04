require 'multi_json'
require 'spec_helper'

describe RealSelf::Stream::Error do
  
  before :each do
    @error = RealSelf::Stream::Error.new('TestError', 'sample error message')
  end

  describe "#new" do
    it "creates a new Error object" do
      @error.should be_an_instance_of RealSelf::Stream::Error
    end
  end

  describe "#to_h" do
    it "creates a hash representation of the error" do
      @error.to_h.should eql ({:type => 'TestError', :message => 'sample error message'})
    end
  end

  describe "#==" do
    it "compares two errors" do
      other = RealSelf::Stream::Error.new('TestError', 'sample error message')

      (@error == other).should be_true
      @error.should eql other

      other = RealSelf::Stream::Error.new('TestError2', 'sample error message 2')

      (@error == other).should be_false
      @error.should_not eql other      
    end
  end

  describe "#to_s" do
    it "converts an Error to a JSON string" do
      json = @error.to_s
      hash = MultiJson.decode(json)

      error = RealSelf::Stream::Error.new(hash['type'], hash['message'])
      @error.should eql error
    end
  end

end