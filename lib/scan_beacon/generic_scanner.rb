module ScanBeacon
  class GenericScanner

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
      @beacons = []
      next_cycle = Time.now + @cycle_seconds
      keep_scanning = true
      each_advertisement do |data, device, rssi|
        detect_beacon(data, device, rssi) unless data.nil?

        if Time.now > next_cycle
          if block_given?
            next_cycle = Time.now + @cycle_seconds
            yield @beacons
            @beacons = []
          else
            keep_scanning = false
          end
        end
      end
      return @beacons unless block_given?
    end

    def each_advertisement
      raise NotImplementedError
    end

    def detect_beacon(data, device, rssi)
      beacon = nil
      if @parsers.detect {|parser| beacon = parser.parse(data) }
        beacon.mac = device
        add_beacon(beacon, rssi)
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
