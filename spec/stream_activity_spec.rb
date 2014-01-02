require 'multi_json'
require 'spec_helper'
require 'pp'

describe RealSelf::Stream::StreamActivity do

  def example_hash
    {
        :object => {:type => "dr", :id => "1234"},
        :activity => {:title => "sample activity title",
                      :published => "1970-01-01T00:00:00+00:00",
                      :actor => {:type => "dr", :id => "1234"},
                      :verb => "author",
                      :object => {:type => "answer", :id => "2345"},
                      :relatives => [{:type => "topic", :id => "4567"}],
                      :uuid => "f364c40c-6e91-4064-a825-faae79c10254",
                      :target => {:type => "question", :id => "3456"}},
        :reasons => [
            {:type => "dr", :id => "1234"},
            {:type => "topic", :id => "4567"}]
    }
  end

  def example_json
    MultiJson::encode(example_hash)
  end

  def example_activity
    RealSelf::Stream::Activity.new(
      'sample activity title',
      DateTime.parse('1970-01-01T00:00:00Z'),
      RealSelf::Stream::Objekt.new('dr', 1234),
      'author',
      RealSelf::Stream::Objekt.new('answer', 2345),
      RealSelf::Stream::Objekt.new('question', 3456),
      [RealSelf::Stream::Objekt.new('topic', 4567)],
      'f364c40c-6e91-4064-a825-faae79c10254'
    )
  end

  def example_stream_activity
    RealSelf::Stream::StreamActivity.new(
      RealSelf::Stream::Objekt.new('dr', 1234),
      example_activity,
      [RealSelf::Stream::Objekt.new('dr', 1234),
       RealSelf::Stream::Objekt.new('topic', 4567)]
    )    
  end

  before :each do
    @stream_activity = example_stream_activity
  end

  describe '::from_hash' do
    it 'takes a hash and returns a new instance' do
      @stream_activity.should eql RealSelf::Stream::StreamActivity.from_hash(example_hash)
    end
  end

  describe '::from_json' do
    it 'takes a JSON string and returns a new instance' do
      @stream_activity.should eql RealSelf::Stream::StreamActivity.from_json(example_json)
    end
  end

  describe "#new" do
    it "takes two or three parameters and returns an Objekt object" do
      @stream_activity.should be_an_instance_of RealSelf::Stream::StreamActivity
    end
  end

  describe "#object" do
    it "returns an Objekt" do
     @stream_activity.object.should be_an_instance_of RealSelf::Stream::Objekt
    end
  end

  describe "#activity" do
    it "returns an Activity" do
      @stream_activity.activity.should be_an_instance_of RealSelf::Stream::Activity
    end
  end 

  describe "#reasons" do
    it "returns an array of Objekts" do
      @stream_activity.reasons.length.should eql 2

      @stream_activity.reasons.each do |reason|
        reason.should be_an_instance_of RealSelf::Stream::Objekt
      end
    end
  end 

  describe "#to_h" do
    it "returns a hash" do
      hash = @stream_activity.to_h

      hash[:object].should eql ({:type => 'dr', :id => '1234'})
      hash[:activity].should eql @stream_activity.activity.to_h
      hash[:reasons].length.should eql 2
      hash[:reasons].should include({:type => 'dr', :id => '1234'}, {:type => 'topic', :id => '4567'})
    end
  end

  describe "#==" do
    it "compares two stream items" do
      (@stream_activity == example_stream_activity).should be_true
      
      other = example_stream_activity
      other.object.id = '0000'
      @stream_activity.should_not eql other
    end
  end

  describe "#to_s" do
    it "returns a JSON string" do
      json = @stream_activity.to_s
      MultiJson::encode(json)
    end
  end

end