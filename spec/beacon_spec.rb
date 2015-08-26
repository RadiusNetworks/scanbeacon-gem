require 'spec_helper'
require 'scan_beacon'

RSpec.describe ScanBeacon::Beacon do
  let(:beacon) {
    beacon = ScanBeacon::Beacon.new(
      ids: ["2F234454CF6D4A0FADF2F4911BA9FFA6",2,3],
      power: -74,
      beacon_type: :mybeacon
    )
  }

  it "counts advertisements" do
    beacon.add_rssi(-80)
    expect { beacon.add_rssi(-82) }.to change{ beacon.ad_count}.by(1)
  end

  it "can return the first id as a formatted uuid" do
    expect( beacon.uuid ).to eq "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6"
  end

  it "can return the second id as major" do
    expect( beacon.major ).to eq 2
  end

  it "can return the third id as minor" do
    expect( beacon.minor ).to eq 3
  end
end
