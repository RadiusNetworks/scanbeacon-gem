module ScanBeacon
  class CoreBluetoothScanner
    include ScanBeacon::CoreBluetooth

    attr_reader :beacons

    def initialize(opts = {})
      @parsers = BeaconParser.default_parsers
      @beacons = []
    end

    def scan
      cb_scan do |scan|
        beacon = nil
        if @parsers.detect {|parser| beacon = parser.parse(scan[:data]) }
          beacon.mac = scan[:device]
          add_beacon(beacon, scan[:rssi])
        end
        yield @beacons
        @beacons = []
        true
      end
    end

    def add_beacon(beacon, rssi)
      if idx = @beacons.find_index(beacon)
        @beacons[idx].add_type beacon.beacon_types.first
        beacon = @beacons[idx]
      else
        @beacons << beacon
      end
      beacon.add_rssi(rssi)
    end
  end
end
