require 'timeout'

module ScanBeacon
  class BLE112Scanner

    attr_reader :beacons

    def initialize(opts = {})
      @device = BLE112Device.new opts[:port]
      @cycle_seconds = opts[:cycle_seconds] || 1
      @parsers = BeaconParser.default_parsers
      @beacons = []
    end

    def add_parser(parser)
      @parsers << parser
    end

    def scan
      @device.open do |device|
        device.start_scan
        cycle_end = Time.now + @cycle_seconds

        begin
          scanning = true
          while scanning do
            check_for_beacon( device.read )
            if Time.now > cycle_end
              if block_given?
                scanning = yield(@beacons) != false
                @beacons = []
                cycle_end = Time.now + @cycle_seconds
              else
                scanning = false
              end
            end
          end
        ensure
          device.stop_scan
        end
      end
      return @beacons unless block_given?
    end

    def check_for_beacon(response)
      if response.advertisement?
        beacon = nil
        if @parsers.detect {|parser| beacon = parser.parse(response.advertisement_data) }
          beacon.mac = response.mac
          add_beacon(beacon, response.rssi)
        end
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
