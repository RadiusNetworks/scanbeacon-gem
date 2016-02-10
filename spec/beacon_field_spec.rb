require 'spec_helper'
require 'scan_beacon'

module ScanBeacon
  RSpec.describe Beacon::Field do

    it "can be initialized with a hex string" do
      id = Beacon::Field.new(hex: "aabbccdd")
      expect( id.bytes ).to eq "\xaa\xbb\xcc\xdd".force_encoding("ASCII-8BIT")
    end

    it "can be initialized with a byte string" do
      id = Beacon::Field.new(bytes: "\xaa\xbb\xcc\xdd")
      expect( id.bytes ).to eq "\xaa\xbb\xcc\xdd".force_encoding("ASCII-8BIT")
    end

    it "can be initialized with a 8bit number" do
      id = Beacon::Field.new(number: 200, length: 1)
      expect( id.bytes ).to eq "\xc8".force_encoding("ASCII-8BIT")
    end

    it "can be initialized with a 16bit number" do
      id = Beacon::Field.new(number: 10000, length: 2)
      expect( id.bytes ).to eq "\x27\x10".force_encoding("ASCII-8BIT")
    end

    it "can be initialized with a 32bit number" do
      id = Beacon::Field.new(number: 100000, length: 4)
      expect( id.bytes ).to eq "\x00\x01\x86\xa0".force_encoding("ASCII-8BIT")
    end

    it "can be initialized with a 64bit number" do
      id = Beacon::Field.new(number: 21474836470, length: 8)
      expect( id.bytes ).to eq "\x00\x00\x00\x04\xFF\xFF\xFF\xF6".force_encoding("ASCII-8BIT")
    end

    it "can convert to a hex string" do
      id = Beacon::Field.new(number: 10000, length: 2)
      expect( id.to_hex ).to eq "2710"
    end

    it "can be initialized with a uuid with dashes" do
      id = Beacon::Field.new hex: "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6"
      expect(id.to_hex ).to eq "2f234454cf6d4a0fadf2f4911ba9ffa6"
    end

    it "can tell if it equals another BeaconId" do
      id1 = Beacon::Field.new(number: 10000, length: 2)
      id2 = Beacon::Field.new(number: 10000, length: 2)
      expect( id1 ).to eq( id2 )
    end
    it "can tell if it does not equal another BeaconId" do
      id1 = Beacon::Field.new(number: 10000, length: 2)
      id2 = Beacon::Field.new(number: 20000, length: 2)
      expect( id1 ).to_not eq( id2 )
    end

    it "can interpret a two byte field as a 8:8 fixed point number" do
      data = Beacon::Field.new(hex: "0240")
      expect( data.to_f ).to eq(2.25)
      data = Beacon::Field.new(hex: "fdc0")
      expect( data.to_f ).to eq(-2.25)
    end
  end
end
