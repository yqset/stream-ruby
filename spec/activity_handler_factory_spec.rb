# require 'realself/stream/activity_handler'
require 'spec_helper'

describe RealSelf::Stream::ActivityHandlerFactory do

  class TestHandler

  end

  class TestHandler2

  end

  class TestStreamActivityHandler

  end

  before(:each) do
    RealSelf::Stream::ActivityHandlerFactory.register_handler(
      'test.message.type',
      RealSelf::Stream::ContentType::ACTIVITY,
      TestHandler
    )

    RealSelf::Stream::ActivityHandlerFactory.register_handler(
      'test2.message.type',
      RealSelf::Stream::ContentType::ACTIVITY,
      TestHandler2
    )

    RealSelf::Stream::ActivityHandlerFactory.register_handler(
      'test.message.type',
      RealSelf::Stream::ContentType::STREAM_ACTIVITY,
      TestStreamActivityHandler
    )
  end


  describe "#create" do

    it "raises an error for unregistered handler types" do
      expect{
        RealSelf::Stream::ActivityHandlerFactory.create(
          'bogus.message.type',
          RealSelf::Stream::ContentType::ACTIVITY
        )
      }.to raise_error
    end

    context "when no initialization block is provided" do

      it "creates a handler instance" do
        handler = RealSelf::Stream::ActivityHandlerFactory.create(
          'test.message.type',
          RealSelf::Stream::ContentType::ACTIVITY
        )

        expect(handler).to be_instance_of(TestHandler)
      end


      it "creates the correct handler based on content type" do
        handler = RealSelf::Stream::ActivityHandlerFactory.create(
          'test.message.type',
          RealSelf::Stream::ContentType::ACTIVITY
        )

        expect(handler).to be_instance_of(TestHandler)

        handler = RealSelf::Stream::ActivityHandlerFactory.create(
          'test.message.type',
          RealSelf::Stream::ContentType::STREAM_ACTIVITY
        )

        expect(handler).to be_instance_of(TestStreamActivityHandler)
      end

    end

    context "when an initialization block is provided" do

      it "creates a handler instance and passes it to the block" do
        test_handler = nil

        handler = RealSelf::Stream::ActivityHandlerFactory.create(
          'test.message.type',
          RealSelf::Stream::ContentType::ACTIVITY
        ) do |new_handler|
          test_handler = new_handler
        end

        expect(handler).to eql test_handler
      end

    end

  end


  describe "#register_handler" do

    it "registers a handler" do
      handlers = RealSelf::Stream::ActivityHandlerFactory.registered_handlers
      expect(handlers.empty?).to be false
      expect(handlers.include?("#{RealSelf::Stream::ContentType::ACTIVITY}::test.message.type")).to be true
    end

    it "registers handlers of multiple content types" do
      handlers = RealSelf::Stream::ActivityHandlerFactory.registered_handlers

      expect(handlers.empty?).to be false
      expect(handlers.size).to eql 3
      expect(handlers.include?("#{RealSelf::Stream::ContentType::ACTIVITY}::test.message.type")).to be true
      expect(handlers.include?("#{RealSelf::Stream::ContentType::ACTIVITY}::test2.message.type")).to be true
      expect(handlers.include?("#{RealSelf::Stream::ContentType::STREAM_ACTIVITY}::test.message.type")).to be true
    end

  end

end