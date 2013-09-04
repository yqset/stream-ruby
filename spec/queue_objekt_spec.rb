require 'multi_json'
require 'pp'
require 'spec_helper'

describe RealSelf::Stream::QueueItem do

  def queue_objekt(i) 
    {
      :type => "answer",
      :id => i.to_s,
      :followers =>
      [
        {
          :type => "user",
          :id => "2345"
        },
        {
          :type => "user",
          :id => "3456"
        } 
      ]      
    }
  end

  before :each do
    @queue_objekt = RealSelf::Stream::QueueObjekt.from_json(MultiJson.encode(queue_objekt(1234)))
  end

  describe "#new" do
    it "takes 2 or 3 parameters and returns a QueueObjekt" do
      queue_objekt = RealSelf::Stream::QueueObjekt.new("answer", 1234)
      queue_objekt.should be_an_instance_of RealSelf::Stream::QueueObjekt
      queue_objekt.followers.length.should eql 0

      queue_objekt = RealSelf::Stream::QueueObjekt.new("answer", 1234,
        [RealSelf::Stream::Objekt.new('user', 2345),
          RealSelf::Stream::Objekt.new('user', 3456)]
      )
      queue_objekt.should be_an_instance_of RealSelf::Stream::QueueObjekt
      queue_objekt.followers.length.should eql 2      
    end
  end

  describe "#followers" do
    it "returns an array of Objekts" do
      @queue_objekt.followers.length.should eql 2
      @queue_objekt.followers.should include(
        RealSelf::Stream::Objekt.new('user', 2345),
        RealSelf::Stream::Objekt.new('user', 3456)
      )
    end
  end

  describe "#to_h" do
    it "returns a hash representing the QueueObjekt" do
      queue_objekt(1234).should eql @queue_objekt.to_h
    end
  end

  describe "#to_objekt" do
    it "converts a QueueItem in to an Objekt" do
      objekt = @queue_objekt.to_objekt
      objekt.should be_an_instance_of RealSelf::Stream::Objekt
      objekt.id.should eql "1234"
      objekt.type.should eql "answer"
    end
  end

  describe "::from_json" do
    it "takes a JSON string and returns a QueueObjekt" do
      @queue_objekt.should be_an_instance_of RealSelf::Stream::QueueObjekt
      @queue_objekt.should be_an_kind_of RealSelf::Stream::Objekt
    end
  end

end