require 'spec_helper'
require 'scan_beacon'

module ScanBeacon
  RSpec.describe BeaconId do

    it "can be initialized with a hex string" do
      id = BeaconId.new(hex: "aabbccdd")
      expect( id.bytes ).to eq "\xaa\xbb\xcc\xdd".force_encoding("ASCII-8BIT")
    end

    it "can be initialized with a byte string" do
      id = BeaconId.new(bytes: "\xaa\xbb\xcc\xdd")
      expect( id.bytes ).to eq "\xaa\xbb\xcc\xdd".force_encoding("ASCII-8BIT")
    end

    it "can be initialized with a 8bit number" do
      id = BeaconId.new(number: 200, length: 1)
      expect( id.bytes ).to eq "\xc8".force_encoding("ASCII-8BIT")
    end

    it "can be initialized with a 16bit number" do
      id = BeaconId.new(number: 10000, length: 2)
      expect( id.bytes ).to eq "\x27\x10".force_encoding("ASCII-8BIT")
    end

    it "can be initialized with a 32bit number" do
      id = BeaconId.new(number: 100000, length: 4)
      expect( id.bytes ).to eq "\x00\x01\x86\xa0".force_encoding("ASCII-8BIT")
    end

    it "can be initialized with a 64bit number" do
      id = BeaconId.new(number: 21474836470, length: 8)
      expect( id.bytes ).to eq "\x00\x00\x00\x04\xFF\xFF\xFF\xF6".force_encoding("ASCII-8BIT")
    end

    it "can convert to a hex string" do
      id = BeaconId.new(number: 10000, length: 2)
      expect( id.to_hex ).to eq "2710"
    end

    it "can tell if it equals another BeaconId" do
      id1 = BeaconId.new(number: 10000, length: 2)
      id2 = BeaconId.new(number: 10000, length: 2)
      expect( id1 ).to eq( id2 )
    end
    it "can tell if it does not equal another BeaconId" do
      id1 = BeaconId.new(number: 10000, length: 2)
      id2 = BeaconId.new(number: 20000, length: 2)
      expect( id1 ).to_not eq( id2 )
    end
  end
end
