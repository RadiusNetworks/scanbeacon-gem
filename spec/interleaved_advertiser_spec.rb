require 'spec_helper'
require 'scan_beacon'

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
    }.to raise_error(StandardError)    
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

  it "returns beacon list with inspect" do
    base_advertiser = ScanBeacon::BLE112Advertiser.new
    advertiser = ScanBeacon::InterleavedAdvertiser.new(advertiser: base_advertiser, beacons:[beacon, beacon])
    expect(advertiser.inspect).to eq("<InterleavedAdvertiser beacons=[<Beacon ids=2F234454CF6D4A0FADF2F4911BA9FFA6,2,3 rssi=NaN, scans=0, power=-74, type=\"altbeacon\">, <Beacon ids=2F234454CF6D4A0FADF2F4911BA9FFA6,2,3 rssi=NaN, scans=0, power=-74, type=\"altbeacon\">]>")
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
    
    begin
      base_advertiser = ScanBeacon::BlueZAdvertiser.new
    rescue # above fails on a mac
      base_advertiser = ScanBeacon::BLE112Advertiser.new
    end

    advertiser = ScanBeacon::InterleavedAdvertiser.new(
        advertiser: base_advertiser, 
        beacons:[beacon1, beacon2],
        parsers:[parser1, parser2])

    expect(base_advertiser).to receive(:start)    
    allow(base_advertiser).to receive(:stop)  

    advertiser.start
    sleep 0.1
    advertiser.stop
  end

end

