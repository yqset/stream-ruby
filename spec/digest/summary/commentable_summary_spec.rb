require 'spec_helper'
require_relative '../commentable_shared_examples'

describe RealSelf::Stream::Digest::Summary::CommentableSummary do

  describe "#new" do
    it "should raise an error if it's created directly" do
      object = RealSelf::Stream::Objekt.new('bogus', 'object')

      expect{RealSelf::Stream::Digest::Summary::CommentableSummary.new(object)}.to raise_error
    end
  end

end