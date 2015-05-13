require 'spec_helper'

describe RealSelf::Handler::Factory do

  class TestMessageType1Handler
    include RealSelf::Handler::Activity

    def initialize(params = {})
    end
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

  class TestMessageType2StreamActivityHandler1
    include RealSelf::Handler::StreamActivity
    attr_accessor :param_1, :param_2

    def initialize(param_1:, param_2:)
      @param_1 = param_1
      @param_2 = param_2
    end
  end

  before(:each) do
    # activity handlers
    TestMessageType1Handler.register_handler('test.message.type-1')
    TestMessageType2Handler.register_handler('test.message.type-2')
    TestMessageType2Handler2.register_handler('test.message.type-2')

    # stream activity handlers
    TestMessageType1StreamActivityHandler.register_handler('test.message.type-1')
    TestMessageType1StreamActivityHandler2.register_handler('test.message.type-1')

    TestMessageType2StreamActivityHandler1.register_handler('test.message.type-2')
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

    context "when initialization parameters are specified" do

      it "calls the handler constructor with the correct named parameters" do
        handler_params = {:param_1 => 'one', :param_2 => 'two'}

        handlers = RealSelf::Handler::Factory.create(
          'test.message.type-2',
          RealSelf::ContentType::STREAM_ACTIVITY,
          handler_params
          )

        expect(handlers.size).to eql 1
        expect(handlers[0].param_1).to eql 'one'
        expect(handlers[0].param_2).to eql 'two'
      end

    end

  end


  describe '#register_enclosure' do
    it "correctly stores the enclosure module" do
      module TestEnclosure
        def self.handle(message)
          yield
        end
      end
      RealSelf::Handler::Factory.register_enclosure('test.queue.name', TestEnclosure)

      expect(RealSelf::Handler::Factory.enclosure('test.queue.name')).to eql TestEnclosure
    end

    it "uses the default enclosure if none is specified" do
      expect(RealSelf::Handler::Factory.enclosure('default.enclosure.queue')).to eql RealSelf::Handler::Enclosure
    end
  end


  describe "#register_handler" do

    it "registers multiple handlers of different types" do
      handlers = RealSelf::Handler::Factory.registered_handlers
      expect(handlers.size).to eql 7  # one comes from worker_spec.rb
      expect(handlers.include?("#{RealSelf::ContentType::ACTIVITY} => test.message.type-1 => TestMessageType1Handler")).to be true
      expect(handlers.include?("#{RealSelf::ContentType::ACTIVITY} => test.message.type-2 => TestMessageType2Handler")).to be true
      expect(handlers.include?("#{RealSelf::ContentType::ACTIVITY} => test.message.type-2 => TestMessageType2Handler2")).to be true
      expect(handlers.include?("#{RealSelf::ContentType::STREAM_ACTIVITY} => test.message.type-1 => TestMessageType1StreamActivityHandler")).to be true
      expect(handlers.include?("#{RealSelf::ContentType::STREAM_ACTIVITY} => test.message.type-1 => TestMessageType1StreamActivityHandler2")).to be true
      expect(handlers.include?("#{RealSelf::ContentType::STREAM_ACTIVITY} => test.message.type-2 => TestMessageType2StreamActivityHandler1")).to be true
    end

  end

end
