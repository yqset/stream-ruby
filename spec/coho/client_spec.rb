require 'spec_helper'

describe RealSelf::Stream::Coho::Client do

  def test_url
    'http://spaceghostcoasttocoast.com/brak'
  end

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

end
