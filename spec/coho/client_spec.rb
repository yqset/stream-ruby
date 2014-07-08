require 'spec_helper'
# require 'stream_spec_helpers'

include Helpers

describe RealSelf::Stream::Coho::Client do

  let(:test_url) {'http://spaceghostcoasttocoast.com/brak'}

  describe '#base_uri=' do
    it 'sets the base uri' do
      base_uri = test_url
      RealSelf::Stream::Coho::Client.base_uri = base_uri
      expect(RealSelf::Stream::Coho::Client.base_uri).to eql base_uri
    end
  end

  describe '#stubborn_get' do
    it 'retries a request 3 times if it fails' do
      logger = double('Logger')
      expect(logger).to receive(:error).at_least(:once)
      RealSelf::Stream::Coho::Client.logger = logger
      RealSelf::Stream::Coho::Client.wait_interval = 0.00001 # Short wait time for fast tests
      expect(RealSelf::Stream::Coho::Client).to receive(:get).exactly(4).times.and_raise('something broke')
      expect { RealSelf::Stream::Coho::Client.stubborn_get(test_url) }.to raise_error('something broke')
    end
  end

  describe "#follow" do
    it "should raise an error" do
      actor = RealSelf::Stream::Objekt.new('user', 1234)
      object = RealSelf::Stream::Objekt.new('dr', 2345)
      expect{RealSelf::Stream::Coho::Client.follow(actor, object)}.to raise_error
    end
  end

  describe "#unfollow" do
    it "should raise an error" do
      actor = RealSelf::Stream::Objekt.new('user', 1234)
      object = RealSelf::Stream::Objekt.new('dr', 2345)
      expect{RealSelf::Stream::Coho::Client.unfollow(actor, object)}.to raise_error
    end
  end

  describe "#followedby" do
    it 'validates a successful response and parses the response body in to an array of Objekts' do
      Helpers.init(1)
      objekts = objekts_array.map { |obj| obj.to_h }

      response = double('Response', :code => 200, :body => MultiJson.encode(objekts))

      allow(RealSelf::Stream::Coho::Client).to receive(:stubborn_get) { response }

      user = RealSelf::Stream::Objekt.new('user', 1234)
      expect(RealSelf::Stream::Coho::Client.followedby(user)).to eql objekts_array
    end
  end

  describe "#followersof" do
    it 'validates a successful response and parses the response body in to an array of Objekts' do
      Helpers.init(1)
      objekts = objekts_array.map { |obj| obj.to_h }

      response = double('Response', :code => 200, :body => MultiJson.encode(objekts))

      allow(RealSelf::Stream::Coho::Client).to receive(:stubborn_get) { response }

      user = RealSelf::Stream::Objekt.new('user', 1234)
      expect(RealSelf::Stream::Coho::Client.followersof(user)).to eql objekts_array
    end
  end  

  describe "#validate_response" do
    it 'raises an exception when the response code is not 200 | 204' do
      response = double('Response', :code => 400)

      allow(RealSelf::Stream::Coho::Client).to receive(:stubborn_get) { response }

      user = RealSelf::Stream::Objekt.new('user', 1234)
      expect{RealSelf::Stream::Coho::Client.followersof(user)}.to raise_error
    end

    it 'does not an exception when the response code is 200' do
      Helpers.init(1)
      objekts = objekts_array.map { |obj| obj.to_h }

      response = double('Response', :code => 200, :body => MultiJson.encode(objekts))

      allow(RealSelf::Stream::Coho::Client).to receive(:stubborn_get) { response }

      user = RealSelf::Stream::Objekt.new('user', 1234)
      expect{RealSelf::Stream::Coho::Client.followersof(user)}.to_not raise_error
    end
  end     
end
