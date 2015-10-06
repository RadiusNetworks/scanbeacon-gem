require 'spec_helper'
require 'scan_beacon'
require 'scan_beacon/interleaved_advertiser'
require 'scan_beacon/bluez_advertiser'

RSpec.describe ScanBeacon::InterleavedAdvertiser do
  let(:beacon) {
    beacon = ScanBeacon::Beacon.new(
      ids: ["2F234454CF6D4A0FADF2F4911BA9FFA6",2,3],
      power: -74,
      mfg_id: 0x0118,
      beacon_type: :altbeacon
    )
  }
    
  it "disallows construction with mismatched beacons and parsers" do
    base_advertiser = ScanBeacon::BLE112Advertiser.new
    expect {
      advertiser = ScanBeacon::InterleavedAdvertiser.new(advertiser: base_advertiser, beacons:[beacon], parsers:[])
    }.to raise_error()    
  end
  
  it "calls start on base_advertiser when starting" do
    base_advertiser = ScanBeacon::BLE112Advertiser.new
    expect(base_advertiser).to receive(:start)    
    allow(base_advertiser).to receive(:stop)  
    advertiser = ScanBeacon::InterleavedAdvertiser.new(advertiser: base_advertiser, beacons:[beacon])
    advertiser.start
    sleep 0.1
    advertiser.stop
  end
  
  it "allows you to interleave two custom format beacons" do
    beacon1 = ScanBeacon::Beacon.new(
      ids: ["2F234454CF6D4A0FADF2F4911BA9FFA6",11111,1],
      power: -74,
      mfg_id: 0x0118
    )
    beacon2 = ScanBeacon::Beacon.new(
      ids: ["2F234454CF6D4A0FADF2F4911BA9FFA6",11111,2],
      power: -74,
      mfg_id: 0x0118
    )
    parser1 = ScanBeacon::BeaconParser.new :custom1, "m:2-3=beac,i:4-19,i:20-21,i:22-23,p:24-24,d:25-25"
    parser2 = ScanBeacon::BeaconParser.new :custom2, "m:2-3=beac,i:4-19,i:20-21,i:22-23,p:24-24,d:25-25"
    
    base_advertiser = ScanBeacon::BlueZAdvertiser.new
    expect(base_advertiser).to receive(:start)    
    allow(base_advertiser).to receive(:stop)  
    advertiser = ScanBeacon::InterleavedAdvertiser.new(
        advertiser: base_advertiser, 
        beacons:[beacon1, beacon2],
        parsers:[parser1, parser2])
    advertiser.start
    sleep 0.1
    advertiser.stop
  end

end

