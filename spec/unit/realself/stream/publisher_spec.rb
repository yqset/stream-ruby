require 'spec_helper'


describe RealSelf::Stream::Publisher do

  before :each do
    @bunny_session  = double(Bunny::Session)
    @bunny_channel  = double(Bunny::Channel)
    @bunny_exchange = double(Bunny::Exchange)
    @exchange_name  = 'test.exchange'
    @rmq_config     = {
      :heartbeat  => 60,
      :host       => 'localhost',
      :password   => 'guest',
      :port       => 5672,
      :user       => 'guest',
      :vhost      => '/'
    }
  end


  context '#publish' do
    it 'calls the publish method on the exchange correctly' do
      expect(Bunny).to receive(:new)
        .with(@rmq_config)
        .and_return(@bunny_session)

      expect(@bunny_session).to receive(:start)

      expect(@bunny_session).to receive(:create_channel)
        .and_return(@bunny_channel)

      expect(@bunny_channel).to receive(:topic)
        .with(@exchange_name, :durable => true)
        .and_return(@bunny_exchange)


      publisher = RealSelf::Stream::Publisher.new(@rmq_config, @exchange_name)
      activity  = Helpers.user_create_thing_activity

      expect(@bunny_exchange).to receive(:publish)
        .with(
          activity.to_s,
          :content_type => 'application/json',
          :persistent   => true,
          :routing_key  => activity.prototype)

      publisher.publish activity, activity.prototype
    end
  end
end
