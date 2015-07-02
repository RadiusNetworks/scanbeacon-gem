require 'spec_helper'
require 'scan_beacon'

RSpec.describe ScanBeacon::Beacon do
  it "counts advertisements" do
    beacon = ScanBeacon::Beacon.new ids: [1,2,3], power: -74, beacon_type: :mybeacon
    beacon.add_rssi -80
    expect { beacon.add_rssi -82 }.to change{ beacon.ad_count}.by(1)
  end
end
