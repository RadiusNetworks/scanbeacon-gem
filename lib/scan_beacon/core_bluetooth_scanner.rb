module ScanBeacon
  class CoreBluetoothScanner

    attr_reader :beacons

    def initialize(opts = {})
      @cycle_seconds = opts[:cycle_seconds] || 1
      @parsers = BeaconParser.default_parsers
    end

    def add_parser(parser)
      @parsers << parser
    end

    # Scans for BLE beacons using CoreBluetooth on Mac OS X. If a block is given,
    # a beacon array will be yielded.  The scan will continue until the block
    # returns false.  If a block is not given, the method will return an array
    # of beacons after the set cycle_seconds.
    def scan
      @beacons = []
      keep_scanning = true
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
          if block_given?
            keep_scanning = yield(@beacons) != false
            @beacons = []
          else
            keep_scanning = false
          end
        end
        keep_scanning
      end
      return @beacons unless block_given?
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
