require 'timeout'

module ScanBeacon
  class BLE112Scanner
    SCAN_CMD = [0,1,6,2,2].pack('CCCCC')
    SCAN_PARAMS = [0, 5, 6, 7, 200,200, 0].pack('CCCCS<S<C')
    RESET_CMD = [0,1,9,0,0].pack('ccccc')
    MANUFACTURER_AD = 0xFF

    DEFAULT_LAYOUTS = {altbeacon: "m:2-3=beac,i:4-19,i:20-21,i:22-23,p:24-24,d:25-25",
                       ibeacon:   "m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24"}

    attr_reader :beacons

    def initialize(opts = {})
      @port = opts[:port] || Dir.glob("/dev/{cu.usbmodem,ttyACM}*")[0]
      @cycle_seconds = opts[:cycle_seconds] || 1
      @parsers = DEFAULT_LAYOUTS.map {|name, layout| BeaconParser.new name, layout }
      @beacons = []
    end

    def add_parser(parser)
      @parsers << parser
    end

    def scan
      clear_the_buffer
      open_port do |port|
        send_scan_command(port)
        cycle_end = Time.now + @cycle_seconds

        while true do
          byte = port.each_byte.next
          append_to_buffer(byte)
          if Time.now > cycle_end
            yield @beacons
            @beacons = []
            cycle_end = Time.now + @cycle_seconds
          end
        end
      end
    end

    def open_port
      File.open(@port, 'r+b') do |port|
        yield port
      end
    end

    def append_to_buffer(byte)
      if @buffer.size == 0 && (byte == 0x00 || byte == 0x80)
        @buffer << byte
        @packet_type = byte
      elsif @buffer.size == 1
        @buffer << byte
        @payload_length = byte
        @expected_size = 4 + (@packet_type & 0x07) + @payload_length
      elsif @buffer.size > 1
        @buffer << byte
        check_for_beacon
      end
    end

    def check_for_beacon
      if @expected_size && @buffer.size >= @expected_size
        packet_class =  @buffer[2]
        packet_command =  @buffer[3]
        payload = @buffer[4..-1].pack('C*')
        if (@packet_type & 0x80 != 0x00) && (packet_class == 0x06) &&
            (packet_command == 0x00) && @buffer[19] == MANUFACTURER_AD
          data = payload[16..-1]
          beacon = nil
          if @parsers.detect {|parser| beacon = parser.parse(data) }
            beacon.mac = parse_mac(payload)
            add_beacon(beacon, parse_rssi(payload))
          end
        end
        clear_the_buffer
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

    def parse_mac(payload)
      payload[2..7].unpack('H2 H2 H2 H2 H2 H2').join(":")
    end

    def parse_rssi(payload)
      payload[0].unpack('c')[0]
    end

    def clear_the_buffer
      @buffer = []
      @expected_size = nil
    end

    def send_scan_command(port)
      # disconnect any connections
      port.write([0,1,3,0,0].pack('CCCCC'))
      port.read(7)
      # turn off adverts
      port.write([0,2,6,1,0,0].pack('CCCCCC'))
      port.read(6)
      # stop previous scan
      port.write([0,0,6,4].pack('CCCC'))
      port.read(6)
      # write new scan params
      port.write(SCAN_PARAMS)
      port.read(6)
      # start new scan
      port.write(SCAN_CMD)
      port.read(6)
    end
  end
end
