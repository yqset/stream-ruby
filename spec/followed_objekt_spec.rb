require 'multi_json'
require 'pp'
require 'spec_helper'

describe RealSelf::Stream::FollowedObjekt do

  def followed_objekt(i) 
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
    @followed_objekt = RealSelf::Stream::FollowedObjekt.from_json(MultiJson.encode(followed_objekt(1234)))
  end

  describe "#new" do
    it "takes 2 or 3 parameters and returns a FollowedObjekt" do
      followed_objekt = RealSelf::Stream::FollowedObjekt.new("answer", 1234)
      followed_objekt.should be_an_instance_of RealSelf::Stream::FollowedObjekt
      followed_objekt.followers.length.should eql 0

      followed_objekt = RealSelf::Stream::FollowedObjekt.new("answer", 1234,
        [RealSelf::Stream::Objekt.new('user', 2345),
          RealSelf::Stream::Objekt.new('user', 3456)]
      )
      followed_objekt.should be_an_instance_of RealSelf::Stream::FollowedObjekt
      followed_objekt.followers.length.should eql 2      
    end
  end

  describe "#followers" do
    it "returns an array of Objekts" do
      @followed_objekt.followers.length.should eql 2
      @followed_objekt.followers.should include(
        RealSelf::Stream::Objekt.new('user', 2345),
        RealSelf::Stream::Objekt.new('user', 3456)
      )
    end
  end

  describe "#to_h" do
    it "returns a hash representing the FollowedObjekt" do
      followed_objekt(1234).should eql @followed_objekt.to_h
    end
  end

  describe "#to_objekt" do
    it "converts a QueueItem in to an Objekt" do
      objekt = @followed_objekt.to_objekt
      objekt.should be_an_instance_of RealSelf::Stream::Objekt
      objekt.id.should eql "1234"
      objekt.type.should eql "answer"
    end
  end

  describe "::from_json" do
    it "takes a JSON string and returns a FollowedObjekt" do
      @followed_objekt.should be_an_instance_of RealSelf::Stream::FollowedObjekt
      @followed_objekt.should be_an_kind_of RealSelf::Stream::Objekt
    end
  end

end