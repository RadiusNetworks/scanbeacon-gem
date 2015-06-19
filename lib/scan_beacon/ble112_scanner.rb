module ScanBeacon
  class BLE112Scanner
    SCAN_CMD = [0,1,6,2,1].pack('CCCCC')
    SCAN_PARAMS = [0, 5, 6, 7, 200,200, 0].pack('CCCCS<S<C')
    RESET_CMD = [0,1,9,0,0].pack('ccccc')
    MANUFACTURER_AD = 0xFF

    def initialize(opts = {})
      @port = opts[:port] || Dir.glob("/dev/{cu.usbmodem,ttyACM}*")[0]
      @uuid_filter = opts[:uuid]
    end

    def scan(&block)
      clear_the_buffer
      open_port do |port|
        send_scan_command(port)
        port.each_byte do |byte|
          append_to_buffer_and_yield_adverts(byte, &block)
        end
      end
    end

    def open_port
      File.open(@port, 'r+b') do |port|
        yield port
      end
    end

    def append_to_buffer_and_yield_adverts(byte, &block)
      if @buffer.size == 0 && (byte == 0x00 || byte == 0x80)
        @buffer << byte
      elsif @buffer.size == 1
        @buffer << byte
        @expected_size = 4 + (@buffer[0] & 0x07) + @buffer[1]
      elsif @buffer.size > 1
        @buffer << byte
        check_for_beacon_advert(&block)
      end
    end

    def check_for_beacon_advert(&block)
      if @expected_size && @buffer.size >= @expected_size
        packet_type = @buffer[0]
        payload_length = @buffer[1]
        packet_class =  @buffer[2]
        packet_command =  @buffer[3]
        payload = @buffer[4..-1]
        data = payload[11..-1]
        if (packet_type & 0x80 != 0x00) && (packet_class == 0x06) && (packet_command == 0x00) && beacon?(data)
          advert = Advertisement.new(payload.pack('C*'))
          block.call(advert) if @uuid_filter.nil? || @uuid_filter == advert.uuid
        end
        clear_the_buffer
      end
    end

    def beacon?(data)
      data[4] == MANUFACTURER_AD && (ibeacon?(data) || altbeacon?(data))
    end

    def ibeacon?(data)
      data[7] == 0x02 && data[8] == 0x15
    end

    def altbeacon?(data)
      data[7] == 0xBE && data[8] == 0xAC
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
