require 'spec_helper'
require 'scan_beacon'
require 'scan_beacon/interleaved_advertiser'
#  require 'scan_beacon/ble112_advertiser'

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

end

