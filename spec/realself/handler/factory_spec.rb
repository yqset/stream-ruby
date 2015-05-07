require 'spec_helper'

describe RealSelf::Handler::Factory do

  class TestMessageType1Handler
    include RealSelf::Handler::Activity
  end

  class TestMessageType2Handler
    include RealSelf::Handler::Activity
  end

  class TestMessageType2Handler2
    include RealSelf::Handler::Activity
  end

  class TestMessageType1StreamActivityHandler
    include RealSelf::Handler::StreamActivity
  end

  class TestMessageType1StreamActivityHandler2
    include RealSelf::Handler::StreamActivity
  end

  before(:each) do
    # activity handlers
    TestMessageType1Handler.register_handler('test.message.type-1')
    TestMessageType2Handler.register_handler('test.message.type-2')
    TestMessageType2Handler2.register_handler('test.message.type-2')

    # stream activity handlers
    TestMessageType1StreamActivityHandler.register_handler('test.message.type-1')
    TestMessageType1StreamActivityHandler2.register_handler('test.message.type-1')
  end


  describe "#create" do

    it "raises an error for unregistered handler types" do
      expect{
        RealSelf::Handler::Factory.create(
          'bogus.message.type',
          RealSelf::ContentType::ACTIVITY
        )
      }.to raise_error RealSelf::Handler::HandlerFactoryError
    end

    context "when no initialization block is provided" do

      it "creates a handler instance" do
        handlers = RealSelf::Handler::Factory.create(
          'test.message.type-1',
          RealSelf::ContentType::ACTIVITY
        )

        expect(handlers[0]).to be_instance_of(TestMessageType1Handler)
      end


      it "creates the correct handler based on content type" do
        handlers = RealSelf::Handler::Factory.create(
          'test.message.type-1',
          RealSelf::ContentType::ACTIVITY
        )

        expect(handlers[0]).to be_instance_of(TestMessageType1Handler)

        handlers = RealSelf::Handler::Factory.create(
          'test.message.type-1',
          RealSelf::ContentType::STREAM_ACTIVITY
        )

        expect(handlers[0]).to be_instance_of(TestMessageType1StreamActivityHandler)
      end

    end

    context "when an initialization block is provided" do

      it "creates the correct handler instance and passes it to the block" do
        test_handler = nil

        handlers = RealSelf::Handler::Factory.create(
          'test.message.type-2',
          RealSelf::ContentType::ACTIVITY
        ) do |new_handler|
          expect(new_handler.class.ancestors).to include(RealSelf::Handler::Activity)
        end

      end

      it "calls the block once for each handler created" do
        block_call_count = 0

        handlers = RealSelf::Handler::Factory.create(
          'test.message.type-2',
          RealSelf::ContentType::ACTIVITY
        ) do |new_handler|
          block_call_count += 1
        end

        expect(block_call_count).to eql 2
        expect(handlers.size).to eql 2
      end

    end

  end


  describe "#register_handler" do

    it "registers multiple handlers of different types" do
      handlers = RealSelf::Handler::Factory.registered_handlers
      expect(handlers.size).to eql 5
      expect(handlers.include?("#{RealSelf::ContentType::ACTIVITY} => test.message.type-1 => TestMessageType1Handler")).to be true
      expect(handlers.include?("#{RealSelf::ContentType::ACTIVITY} => test.message.type-2 => TestMessageType2Handler")).to be true
      expect(handlers.include?("#{RealSelf::ContentType::ACTIVITY} => test.message.type-2 => TestMessageType2Handler2")).to be true
      expect(handlers.include?("#{RealSelf::ContentType::STREAM_ACTIVITY} => test.message.type-1 => TestMessageType1StreamActivityHandler")).to be true
      expect(handlers.include?("#{RealSelf::ContentType::STREAM_ACTIVITY} => test.message.type-1 => TestMessageType1StreamActivityHandler2")).to be true
    end

  end

end
