module ScanBeacon
  class BlueZAdvertiser < GenericAdvertiser
 
    attr_accessor :addr

    def initialize(opts = {})
      super()
      @device_id = opts[:device_id] || BlueZ.devices.map {|d| d[:device_id]}[0]
    end

    def start(with_rotation = false)
      addr = random_addr if with_rotation
      BlueZ.start_advertising @device_id, nil
    end

    def stop
      BlueZ.stop_advertising @device_id
    end

    def inspect
      "<BlueZAdvertiser ad=#{@ad.inspect}>"
    end

    def update_ad
      self.ad = @parser.generate_ad(@beacon) if @parser && @beacon
      self.start if @advertising
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
