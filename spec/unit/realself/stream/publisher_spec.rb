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


  context '#initalize' do
    it 'defaults to non-threaded mode' do
      default_config = @rmq_config.hmap {|k,v| [k,v]}
      default_config[:threaded] = false

      expect(Bunny).to receive(:new)
        .with(default_config)
        .and_return(@bunny_session)

      expect(@bunny_session).to receive(:start)

        expect(@bunny_session).to receive(:create_channel)
          .and_return(@bunny_channel)

        expect(@bunny_channel).to receive(:topic)
          .with(@exchange_name, :durable => true)
          .and_return(@bunny_exchange)

      publisher = RealSelf::Stream::Publisher.new(@rmq_config, @exchange_name)
    end
  end


  context 'using publisher confirmation' do
    it 'enables confirmation publishing' do
      expect(Bunny).to receive(:new)
        .with(@rmq_config)
        .and_return(@bunny_session)

      expect(@bunny_session).to receive(:start)

      expect(@bunny_session).to receive(:create_channel)
        .twice # once in initialize() and again in confirm_publish_start
        .and_return(@bunny_channel)

      expect(@bunny_channel).to receive(:topic)
        .twice # once in initialize() and again in confirm_publish_start
        .with(@exchange_name, :durable => true)
        .and_return(@bunny_exchange)


      expect(@bunny_channel).to receive(:open?)
        .and_return(true)

      expect(@bunny_channel).to receive(:close)

      expect(@bunny_channel).to receive(:confirm_select)

      publisher = RealSelf::Stream::Publisher.new(@rmq_config, @exchange_name)
      activity  = Helpers.user_create_thing_activity

      publisher.confirm_publish_start([activity])


      expect(@bunny_exchange).to receive(:publish)
        .with(
          activity.to_s,
          :content_type => 'application/json',
          :message_id   => activity.hash,
          :persistent   => true,
          :routing_key  => activity.prototype)

      expect(@bunny_channel).to receive(:open?)
        .and_return(true)

      publisher.publish activity, activity.prototype

      expect(@bunny_channel).to receive(:nacked_set)
        .and_return(Set.new)

      expect(@bunny_channel).to receive(:wait_for_confirms)
        .and_return(true)

      expect(@bunny_channel).to receive(:open?)
        .and_return(true)

      expect(@bunny_channel).to receive(:close)

      publisher.confirm_publish_end
    end

    it 'raises an errror if a publish confirmation is not received' do
      expect(Bunny).to receive(:new)
        .with(@rmq_config)
        .and_return(@bunny_session)

      expect(@bunny_session).to receive(:start)

      expect(@bunny_session).to receive(:create_channel)
        .twice # once in initialize() and again in confirm_publish_start
        .and_return(@bunny_channel)

      expect(@bunny_channel).to receive(:topic)
        .twice # once in initialize() and again in confirm_publish_start
        .with(@exchange_name, :durable => true)
        .and_return(@bunny_exchange)


      expect(@bunny_channel).to receive(:open?)
        .and_return(true)

      expect(@bunny_channel).to receive(:close)

      expect(@bunny_channel).to receive(:confirm_select)

      publisher = RealSelf::Stream::Publisher.new(@rmq_config, @exchange_name)
      activity  = Helpers.user_create_thing_activity

      publisher.confirm_publish_start(activity)

      expect(@bunny_exchange).to receive(:publish)
        .with(
          activity.to_s,
          :content_type => 'application/json',
          :message_id   => activity.hash,
          :persistent   => true,
          :routing_key  => activity.prototype)

      expect(@bunny_channel).to receive(:open?)
        .and_return(true)

      publisher.publish activity, activity.prototype

      expect(@bunny_channel).to receive(:nacked_set)
        .and_return(Set.new([activity.hash]))

      expect(@bunny_channel).to receive(:wait_for_confirms)
        .and_return(true)

      expect(@bunny_channel).to receive(:open?)
        .and_return(true)

      expect(@bunny_channel).to receive(:close)

      expect(RealSelf::logger).to receive(:error)
        .and_call_original

      expect{publisher.confirm_publish_end}.to raise_error RealSelf::Stream::PublisherError
    end

    it 'continues the confirmations after a network error' do
      expect(Bunny).to receive(:new)
        .exactly(RealSelf::Stream::Publisher::MAX_CONNECTION_RETRY + 1)
        .with(@rmq_config)
        .and_return(@bunny_session)

      expect(@bunny_session).to receive(:start)
        .exactly(RealSelf::Stream::Publisher::MAX_CONNECTION_RETRY + 1)

      expect(@bunny_session).to receive(:create_channel)
        .exactly(RealSelf::Stream::Publisher::MAX_CONNECTION_RETRY + 2)
        .and_return(@bunny_channel)

      expect(@bunny_channel).to receive(:topic)
        .exactly(RealSelf::Stream::Publisher::MAX_CONNECTION_RETRY + 2)
        .with(@exchange_name, :durable => true)
        .and_return(@bunny_exchange)


      expect(@bunny_channel).to receive(:open?)
        .exactly(RealSelf::Stream::Publisher::MAX_CONNECTION_RETRY + 1)
        .and_return(true)

      expect(@bunny_channel).to receive(:close)
        .exactly(RealSelf::Stream::Publisher::MAX_CONNECTION_RETRY + 1)

      expect(@bunny_channel).to receive(:confirm_select)
        .exactly(RealSelf::Stream::Publisher::MAX_CONNECTION_RETRY + 1)

      publisher = RealSelf::Stream::Publisher.new(@rmq_config, @exchange_name)
      activity  = Helpers.user_create_thing_activity
      nfe       = ::Bunny::NetworkFailure.new("a bad thing happened", nil)

      publisher.confirm_publish_start(activity)

      expect(@bunny_exchange).to receive(:publish)
        .exactly(RealSelf::Stream::Publisher::MAX_CONNECTION_RETRY + 1)
        .with(
          activity.to_s,
          :content_type => 'application/json',
          :message_id   => activity.hash,
          :persistent   => true,
          :routing_key  => activity.prototype)
        .and_raise(nfe)

      expect(@bunny_channel).to receive(:maybe_kill_consumer_work_pool!)
        .exactly(RealSelf::Stream::Publisher::MAX_CONNECTION_RETRY)
        .times

      expect(@bunny_channel).to receive(:open?)
        .exactly(RealSelf::Stream::Publisher::MAX_CONNECTION_RETRY + 1)
        .and_return(true)

      expect{publisher.publish(activity, activity.prototype)}.to raise_error ::Bunny::NetworkFailure

      expect(@bunny_channel).to receive(:nacked_set)
        .and_return(Set.new)

      expect(@bunny_channel).to receive(:wait_for_confirms)
        .and_return(true)

      expect(@bunny_channel).to receive(:open?)
        .and_return(true)

      expect(@bunny_channel).to receive(:close)

      publisher.confirm_publish_end
    end
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
          :message_id   => activity.hash,
          :persistent   => true,
          :routing_key  => activity.prototype)

      expect(@bunny_channel).to receive(:open?)
        .and_return(true)

      publisher.publish activity, activity.prototype
    end

    it 'attempts to reconnect on network failure' do
      expect(Bunny).to receive(:new)
        .exactly(RealSelf::Stream::Publisher::MAX_CONNECTION_RETRY + 1)
        .times
        .with(@rmq_config)
        .and_return(@bunny_session)

      expect(@bunny_session).to receive(:start)
        .exactly(RealSelf::Stream::Publisher::MAX_CONNECTION_RETRY + 1)
        .times

      expect(@bunny_session).to receive(:create_channel)
        .exactly(RealSelf::Stream::Publisher::MAX_CONNECTION_RETRY + 1)
        .times
        .and_return(@bunny_channel)

      expect(@bunny_channel).to receive(:topic)
        .exactly(RealSelf::Stream::Publisher::MAX_CONNECTION_RETRY + 1)
        .times
        .with(@exchange_name, :durable => true)
        .and_return(@bunny_exchange)

      publisher = RealSelf::Stream::Publisher.new(@rmq_config, @exchange_name)
      activity  = Helpers.user_create_thing_activity
      nfe       = ::Bunny::NetworkFailure.new("a bad thing happened", nil)

      expect(@bunny_exchange).to receive(:publish)
        .exactly(RealSelf::Stream::Publisher::MAX_CONNECTION_RETRY + 1)
        .times
        .with(
          activity.to_s,
          :content_type => 'application/json',
          :message_id   => activity.hash,
          :persistent   => true,
          :routing_key  => activity.prototype)
        .and_raise(nfe)

      expect(@bunny_channel).to receive(:open?)
        .exactly(RealSelf::Stream::Publisher::MAX_CONNECTION_RETRY + 1)
        .times
        .and_return(true, false, false, false)

      expect(@bunny_channel).to receive(:maybe_kill_consumer_work_pool!)
        .exactly(RealSelf::Stream::Publisher::MAX_CONNECTION_RETRY)
        .times

      expect{publisher.publish(activity, activity.prototype)}.to raise_error ::Bunny::NetworkFailure
    end
  end
end
