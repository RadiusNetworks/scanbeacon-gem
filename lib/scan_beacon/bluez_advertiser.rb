module ScanBeacon
  class BlueZAdvertiser
 
    attr_accessor :beacon, :parser, :ad, :addr

    def initialize(opts = {})
      @device_id = opts[:device_id] || BlueZ.devices.map {|d| d[:device_id]}[0]
      raise "No available devices" if @device_id.nil?
      BlueZ.device_up @device_id
      @addr = @initial_addr = BlueZ.devices.find {|d| d[:device_id] == @device_id}[:addr]
      self.beacon = opts[:beacon]
      self.parser = opts[:parser]
      self.parser ||= BeaconParser.default_parsers.find {|parser| parser.beacon_type == beacon.beacon_types.first}
    end

    def beacon=(value)
      @beacon = value
      update_ad
    end

    def parser=(value)
      @parser = value
      update_ad
    end

    def ad=(value)
      @ad = value
      BlueZ.set_advertisement_bytes @device_id, @ad
    end

    def start
      BlueZ.start_advertising @device_id, nil
    end

    def start_with_random_addr
      addr = random_addr
      BlueZ.start_advertising @device_id, addr
    end

    def stop
      BlueZ.stop_advertising @device_id
    end

    def inspect
      "<BlueZAdvertiser ad=#{@ad.inspect}>"
    end

    def update_ad
      self.ad = @parser.generate_ad(@beacon) if @parser && @beacon
    end

    def rotate_addr_and_update_ad
      self.update_ad
      self.stop
      self.start_with_random_addr
    end

    def random_addr
      data = @initial_addr + Time.now.to_s
      new_addr = Digest::SHA256.digest(data)[0..5]
      # the most significant bit must not be set!
      new_addr[0] = [(new_addr[0].unpack("C")[0] & 0x7F)].pack("C")
      new_addr.unpack("H2:H2:H2:H2:H2:H2").join(":")
    end

  end
end
