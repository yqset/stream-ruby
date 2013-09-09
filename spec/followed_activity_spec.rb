require 'multi_json'
require 'spec_helper'

describe RealSelf::Stream::FollowedActivity do

  def followed_activity(i)
  {
    "published" => "2013-08-13T16:36:59Z",
    "title" => "QUEUE ITEM - dr(57433) author answer(1050916) about question(1048591)",
    "actor" => 
    {
      "type" => "dr", 
      "id" => i.to_s,
      "followers" =>
      [
        {
          "type" => "user",
          "id" => "2345"
        }
      ]
    },
    "verb" => "author",
    "object" => 
    {
      "type" => "answer",
      "id" => "1050916",
      "followers" =>
      [
        {
          "type" => "user",
          "id" => "3456"
        },
        {
          "type" => "user",
          "id" => "4567"
        } 
      ]      
    },
    "target" => 
    {
      "type"=>"question", 
      "id"=>"1048591",
      "followers" =>
      [
        {
          "type" => "user",
          "id" => "5678"
        },
        {
          "type" => "user",
          "id" => "6789"
        } 
      ]
    },
    "relatives" => 
    [
      {
        "type" => "topic",
        "id" => "265299",
        "followers" =>
        [
          {
            "type" => "user",
            "id" => "7890"
          },
          {
            "type" => "user",
            "id" => "8901"
          }          
        ]   
      }
    ]
  }  
  end

  before :each do
    @followed_activity = RealSelf::Stream::FollowedActivity.from_json(MultiJson.encode(followed_activity(1234)))
  end

  describe "#to_activity" do
    it "creates an Activity object from a FollowedActivity" do
      activity = @followed_activity.to_activity
      activity.should be_an_instance_of RealSelf::Stream::Activity

      @followed_activity.title.should eql activity.title
      @followed_activity.published.should eql activity.published
      (@followed_activity.actor.to_objekt == activity.actor).should be_true
      @followed_activity.verb.should eql activity.verb
      (@followed_activity.object.to_objekt == activity.object).should be_true
      (@followed_activity.target.to_objekt == activity.target).should be_true
      @followed_activity.relatives.length.should eql activity.relatives.length

      @followed_activity.relatives.each_index do |index|
        (@followed_activity.relatives[index].to_objekt == activity.relatives[index]).should be_true
      end
    end
  end

  describe "#map_followers" do
    it "enumerates all followers of the activity and describes the reason the follower was included" do
      followers_map = {}
      @followed_activity.map_followers do |follower, reason|
        followers_map[reason] = [] if followers_map[reason].nil?
        followers_map[reason] << follower
      end

      followers_map.each do |reason, followers|
        if 'dr' == reason.type
          followers.length.should eql 2
          followers.should include(RealSelf::Stream::Objekt.new('dr', 1234))
          followers.should include(RealSelf::Stream::Objekt.new('user', 2345))
        end

        if 'answer' == reason.type
          followers.length.should eql 3
          followers.should include(
            RealSelf::Stream::Objekt.new('answer', 1050916),
            RealSelf::Stream::Objekt.new('user', 3456),
            RealSelf::Stream::Objekt.new('user', 4567)
          )
        end

        if 'question' == reason.type
          followers.length.should eql 3
          followers.should include(
            RealSelf::Stream::Objekt.new('question', 1048591),
            RealSelf::Stream::Objekt.new('user', 5678),
            RealSelf::Stream::Objekt.new('user', 6789)
          )
        end   

        if 'topic' == reason.type
          followers.length.should eql 3
          followers.should include(
            RealSelf::Stream::Objekt.new('topic', 265299),
            RealSelf::Stream::Objekt.new('user', 7890),
            RealSelf::Stream::Objekt.new('user', 8901)
          )
        end             
      end
    end
  end

  describe "::from_json" do
    it "takes a JSON string and returns a FollowedActivity" do
      @followed_activity.should be_an_instance_of RealSelf::Stream::FollowedActivity
      @followed_activity.should be_an_kind_of RealSelf::Stream::Activity
    end
  end

end