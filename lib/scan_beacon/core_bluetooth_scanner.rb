module ScanBeacon
  class CoreBluetoothScanner

    attr_reader :beacons

    def initialize(opts = {})
      @cycle_seconds = opts[:cycle_seconds] || 1
      @parsers = BeaconParser.default_parsers
      @beacons = []
    end

    def add_parser(parser)
      @parsers << parser
    end

    def scan
      CoreBluetooth::scan do
        sleep @cycle_seconds
        CoreBluetooth::new_adverts.each do |scan|
          beacon = nil
          if @parsers.detect {|parser| beacon = parser.parse(scan[:data]) }
            beacon.mac = scan[:device]
            add_beacon(beacon, scan[:rssi])
          end
        end
        if @beacons.size > 0
          yield @beacons
          @beacons = []
        end
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
