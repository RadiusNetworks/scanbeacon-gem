require 'spec_helper'
require 'scan_beacon'

RSpec.describe ScanBeacon::CoreBluetoothScanner do
  let(:scan) {
    {:device=>"92151608-5EE2-4783-A08B-C17F13A179D7",
     :data=>"\x18\x01\xBE\xAC\xBE\xAC\xBE\xACUSNETWORKSCO\x00\x01\x00\f\xBE\x00",
     :rssi=>-50}
  }
  let(:scanner_opts) { {cycle_seconds: 0} }
  before do
    allow(ScanBeacon::CoreBluetooth).to receive(:new_adverts).and_return( [scan] )
  end

  it "can scan for altbeacons" do
    scanner = ScanBeacon::CoreBluetoothScanner.new scanner_opts
    scanner.scan
    expect(scanner.beacons[0].uuid).to eq("BEACBEAC-5553-4E45-5457-4F524B53434F")
  end

end
