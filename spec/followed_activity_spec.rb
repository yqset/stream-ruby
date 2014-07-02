require 'multi_json'
require 'spec_helper'
require 'securerandom'

describe RealSelf::Stream::FollowedActivity do

  def followed_activity(i)
  {
    "published" => "1970-01-01T00:00:00+00:00",
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
    ], 
    "uuid" => 'f364c40c-6e91-4064-a825-faae79c10254',
    "prototype" => "explicit.prototype.value"
  }  
  end

  before :each do
    @followed_activity = RealSelf::Stream::FollowedActivity.from_json(MultiJson.encode(followed_activity(1234)))
  end

  describe "#to_activity" do
    it "creates an Activity object from a FollowedActivity" do
      activity = @followed_activity.to_activity
      expect(activity).to be_an_instance_of RealSelf::Stream::ActivityV1

      expect(@followed_activity.title).to eql activity.title
      expect(@followed_activity.published).to eql activity.published
      expect(@followed_activity.actor.to_objekt).to eql activity.actor
      expect(@followed_activity.verb).to eql activity.verb
      expect(@followed_activity.object.to_objekt).to eql activity.object
      expect(@followed_activity.target.to_objekt).to eql activity.target
      expect(@followed_activity.relatives.length).to eql activity.relatives.length
      expect(@followed_activity.uuid).to eql activity.uuid
      expect(@followed_activity.prototype).to eql activity.prototype

      @followed_activity.relatives.each_index do |index|
        expect(@followed_activity.relatives[index].to_objekt).to eql activity.relatives[index]
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
          expect(followers.length).to eql 2
          expect(followers).to include(RealSelf::Stream::Objekt.new('dr', 1234))
          expect(followers).to include(RealSelf::Stream::Objekt.new('user', 2345))
        end

        if 'answer' == reason.type
          expect(followers.length).to eql 3
          expect(followers).to include(
            RealSelf::Stream::Objekt.new('answer', 1050916),
            RealSelf::Stream::Objekt.new('user', 3456),
            RealSelf::Stream::Objekt.new('user', 4567)
          )
        end

        if 'question' == reason.type
          expect(followers.length).to eql 3
          expect(followers).to include(
            RealSelf::Stream::Objekt.new('question', 1048591),
            RealSelf::Stream::Objekt.new('user', 5678),
            RealSelf::Stream::Objekt.new('user', 6789)
          )
        end   

        if 'topic' == reason.type
          expect(followers.length).to eql 3
          expect(followers).to include(
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
      expect(@followed_activity).to be_an_instance_of RealSelf::Stream::FollowedActivityV1
      expect(@followed_activity).to be_an_kind_of RealSelf::Stream::FollowedActivity
      expect(@followed_activity).to be_an_kind_of RealSelf::Stream::Activity
    end
  end

  describe "#to_h" do
    it "returns a hash representation of the followed activity" do
      hash = @followed_activity.to_h
      json = MultiJson.encode(followed_activity(1234))
      hash2 = MultiJson.decode(json, { :symbolize_keys => true })

      expect(hash).to eql hash2
    end
  end

  describe "#to_version" do
    it "takes a followed activity and asks to convert it to version 1 format" do
      expect(@followed_activity.to_version(1)).to eql @followed_activity
    end

    it "takes a followed activity and raises an error when trying to convert to an unknown version" do
      expect{@followed_activity.to_version(2)}.to raise_error
    end
  end

end