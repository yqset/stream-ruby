require 'multi_json'
require 'spec_helper'

describe RealSelf::Stream::Objekt do

  def example_hash
    { :type => 'user', :id => '1234' }
  end

  def example_json
    '{"type": "user", "id": "1234"}'
  end

  before :each do
    @objekt = RealSelf::Stream::Objekt.new('user', 1234)
  end

  describe '#new' do
    it 'takes two parameters and returns an Objekt object' do
      @objekt.should be_an_instance_of RealSelf::Stream::Objekt
    end
  end

  describe '::from_hash' do
    it 'takes a hash and returns a new instance' do
      @objekt.should eql RealSelf::Stream::Objekt.from_hash(example_hash)
    end
  end

  describe '::from_json' do
    it 'takes a JSON string and returns a new instance' do
      @objekt.should eql RealSelf::Stream::Objekt.from_json(example_json)
    end
  end

  describe '#type' do
    it 'returns the correct type' do
      @objekt.type.should eql 'user'
    end
  end

  describe '#id' do
    it 'returns the correct type' do
      @objekt.id.should eql '1234'
    end
  end 

  describe '#to_h' do
    it 'returns a hash' do
      @objekt.to_h.should eql example_hash
    end
  end

  describe '#==' do
    it 'compares two objekts' do
      other = RealSelf::Stream::Objekt.new('user', 1234)
      (@objekt == other).should be_true
      other.id = '2345'
      (@objekt == other).should be_false
    end
  end

  describe '#to_s' do
    it 'returns a JSON string' do
      @objekt.to_s.should eql MultiJson.encode(example_hash)
    end
  end

  describe '::from_json' do
    it 'creates an objekt from a JSON string' do
      json = MultiJson.encode(example_hash)
      objekt = RealSelf::Stream::Objekt.from_json(json)
      objekt.should be_an_instance_of RealSelf::Stream::Objekt
      objekt.should eql @objekt
    end
  end
end