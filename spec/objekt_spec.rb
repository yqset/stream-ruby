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
      expect(@objekt).to be_an_instance_of RealSelf::Stream::Objekt
    end
  end

  describe '::from_hash' do
    it 'takes a hash and returns a new instance' do
      expect(@objekt).to eql RealSelf::Stream::Objekt.from_hash(example_hash)
    end
  end

  describe '::from_json' do
    it 'takes a JSON string and returns a new instance' do
      expect(@objekt).to eql RealSelf::Stream::Objekt.from_json(example_json)
    end
  end

  describe '#type' do
    it 'returns the correct type' do
      expect(@objekt.type).to eql 'user'
    end
  end

  describe '#id' do
    it 'returns the correct type' do
      expect(@objekt.id).to eql '1234'
    end
  end 

  describe '#to_h' do
    it 'returns a hash' do
      expect(@objekt.to_h).to eql example_hash
    end
  end

  describe '#==' do
    it 'compares two objekts' do
      other = RealSelf::Stream::Objekt.new('user', 1234)
      expect(@objekt).to eql other

      other.id = '2345'
      expect(@objekt).to_not eql other
    end
  end

  describe '#to_s' do
    it 'returns a JSON string' do
      expect(@objekt.to_s).to eql MultiJson.encode(example_hash)
    end
  end

  describe '::from_json' do
    it 'creates an objekt from a JSON string' do
      json = MultiJson.encode(example_hash)
      objekt = RealSelf::Stream::Objekt.from_json(json)
      expect(objekt).to be_an_instance_of RealSelf::Stream::Objekt
      expect(objekt).to eql @objekt
    end
  end
end