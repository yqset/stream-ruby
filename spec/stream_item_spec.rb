require 'multi_json'
require 'spec_helper'
require 'pp'

describe RealSelf::Stream::StreamItem do

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

  def example_stream_item 
    RealSelf::Stream::StreamItem.new(
      RealSelf::Stream::Objekt.new('dr', 1234),
      example_activity,
      [RealSelf::Stream::Objekt.new('dr', 1234),
       RealSelf::Stream::Objekt.new('topic', 4567)]
    )    
  end

  before :each do
    @stream_item = example_stream_item
  end

  describe "#new" do
    it "takes two or three parameters and returns an Objekt object" do
      @stream_item.should be_an_instance_of RealSelf::Stream::StreamItem
    end
  end

  describe "#object" do
    it "returns an Objekt" do
     @stream_item.object.should be_an_instance_of RealSelf::Stream::Objekt
    end
  end

  describe "#activity" do
    it "returns an Activity" do
      @stream_item.activity.should be_an_instance_of RealSelf::Stream::Activity
    end
  end 

  describe "#reasons" do
    it "returns an array of Objekts" do
      @stream_item.reasons.length.should eql 2

      @stream_item.reasons.each do |reason|
        reason.should be_an_instance_of RealSelf::Stream::Objekt
      end
    end
  end 

  describe "#to_h" do
    it "returns a hash" do
      hash = @stream_item.to_h

      hash[:object].should eql ({:type => 'dr', :id => '1234'})
      hash[:activity].should eql @stream_item.activity.to_h
      hash[:reasons].length.should eql 2
      hash[:reasons].should include({:type => 'dr', :id => '1234'}, {:type => 'topic', :id => '4567'})
    end
  end

  describe "#==" do
    it "compares two stream items" do
      (@stream_item == example_stream_item).should be_true
      
      other = example_stream_item
      other.object.id = '0000'
      (@stream_item == other).should be_false
    end
  end

  describe "#to_s" do
    it "returns a JSON string" do
      json = @stream_item.to_s
      hash = MultiJson::encode(json) 
    end
  end

end