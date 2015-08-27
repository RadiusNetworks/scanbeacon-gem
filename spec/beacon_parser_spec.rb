require 'spec_helper'
require 'scan_beacon'

RSpec.describe ScanBeacon::BeaconParser do

  let(:payload) {
    "\xB2\x02\xD7\e\x00\xEE\xF3\f\x00\xFF\x1F\x02\x01\x06\e\xFFZ\x00\xBE\xAC/#DT\xCFmJ\x0F\xAD\xF2\xF4\x91\e\xA9\xFF\xA6\xCE\xC3\x00\x83\xB9\r".force_encoding("ASCII-8BIT")
  }
  let(:data) { payload[16..-1] }
  let(:altbeacon_layout) { "m:2-3=beac,i:4-19,i:20-21,i:22-23,p:24-24,d:25-25" }
  let(:altbeacon_parser) { ScanBeacon::BeaconParser.new :altbeacon, altbeacon_layout }
  let(:generated_ad) {
    "\e\xFF\x18\x01\xBE\xAC/#DT\xCFmJ\x0F\xAD\xF2\xF4\x91\e\xA9\xFF\xA6\x00\v\x00\v\xC5\x05".force_encoding("ASCII-8BIT")
  }

  it "can use an altbeacon layout to parse an altbeacon advertisement" do
    expect( altbeacon_parser.matches? data ).to be(true)
  end

  it "can parse altbeacon identifiers" do
    expect( altbeacon_parser.parse_ids(data).map(&:value) ).to match_array(['2f234454cf6d4a0fadf2f4911ba9ffa6', 52931, 131])
  end

  it "can parse altbeacon power" do
    expect( altbeacon_parser.parse_power(data) ).to equal(-71)
  end

  it "doesn't require a power field" do
    layout = "m:0-3=18017e1e,i:4-9,d:10-10"
    parser = ScanBeacon::BeaconParser.new(:no_power, layout)
    power = parser.parse_power(payload)
    expect( power ).to be nil
  end

  it "can generate altbeacon advertisement bytes" do
    beacon = ScanBeacon::Beacon.new(
      ids: ["2F234454CF6D4A0FADF2F4911BA9FFA6", 11,11],
      data: [5],
      power: -59,
      mfg_id: 0x0118,
      beacon_type: :altbeacon
    )
    expect( altbeacon_parser.generate_ad(beacon) ).to eq( generated_ad )
  end
end
