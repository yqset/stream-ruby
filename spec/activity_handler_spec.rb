require 'realself/stream/activity_handler'

describe RealSelf::Stream::ActivityHandler do

  class TestHandler < RealSelf::Stream::ActivityHandler
    register_handler('test.message.type')
  end

  describe "#create" do

    context "when no initialization block is provided" do

      it "creates a handler instance" do
        handler = RealSelf::Stream::ActivityHandler.create('test.message.type')

        expect(handler).to be_kind_of(RealSelf::Stream::ActivityHandler)
        expect(handler).to be_instance_of(TestHandler)
      end

      it "raises an error for unregistered handler types" do
        expect{ RealSelf::Stream::ActivityHandler.create('bogus.message.type') }.to raise_error
      end
    end

    context "when an initialization block is provided" do

      it "creates a handler instance and passes it to the block" do

        test_handler = nil

        handler = RealSelf::Stream::ActivityHandler.create('test.message.type') do |new_handler|
          test_handler = new_handler
        end

        expect(handler).to eql test_handler

      end

    end

  end

  describe "#register_handler" do

    it "registers a handler" do
      handlers = RealSelf::Stream::ActivityHandler.registered_handlers
      expect(handlers.empty?).to be false
      expect(handlers.include?('test.message.type')).to be true
    end

  end

end