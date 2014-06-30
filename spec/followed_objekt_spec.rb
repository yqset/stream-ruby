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
      expect(followed_objekt).to be_an_instance_of RealSelf::Stream::FollowedObjekt
      expect(followed_objekt.followers.length).to eql 0

      followed_objekt = RealSelf::Stream::FollowedObjekt.new("answer", 1234,
        [RealSelf::Stream::Objekt.new('user', 2345),
          RealSelf::Stream::Objekt.new('user', 3456)]
      )
      expect(followed_objekt).to be_an_instance_of RealSelf::Stream::FollowedObjekt
      expect(followed_objekt.followers.length).to eql 2      
    end
  end

  describe "#followers" do
    it "returns an array of Objekts" do
      expect(@followed_objekt.followers.length).to eql 2
      expect(@followed_objekt.followers).to include(
        RealSelf::Stream::Objekt.new('user', 2345),
        RealSelf::Stream::Objekt.new('user', 3456)
      )
    end
  end

  describe "#to_h" do
    it "returns a hash representing the FollowedObjekt" do
      expect(followed_objekt(1234)).to eql @followed_objekt.to_h
    end
  end

  describe "#to_objekt" do
    it "converts a QueueItem in to an Objekt" do
      objekt = @followed_objekt.to_objekt
      expect(objekt).to be_an_instance_of RealSelf::Stream::Objekt
      expect(objekt.id).to eql "1234"
      expect(objekt.type).to eql "answer"
    end
  end

  describe "::from_json" do
    it "takes a JSON string and returns a FollowedObjekt" do
      expect(@followed_objekt).to be_an_instance_of RealSelf::Stream::FollowedObjekt
      expect(@followed_objekt).to be_an_kind_of RealSelf::Stream::Objekt
    end
  end

end