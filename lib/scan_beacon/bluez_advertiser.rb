module ScanBeacon
  class BlueZAdvertiser < GenericIndividualAdvertiser
 
    attr_reader :addr

    def initialize(opts = {})
      @device_id = opts[:device_id] || BlueZ.devices.map {|d| d[:device_id]}[0]
      raise "No available devices" if @device_id.nil?
      BlueZ.device_up @device_id
      addr = @initial_addr = BlueZ.devices.find {|d| d[:device_id] == @device_id}[:addr]
      super(opts)
    end

    def start(with_rotation = false)
      addr = random_addr if with_rotation
      BlueZ.set_advertisement_bytes @device_id, @ad
      # You must call start advertising any time you change the advertisement bytes
      # otherwise they won't take
      BlueZ.start_advertising @device_id, addr
      @advertising=true
    end

    def stop
      BlueZ.stop_advertising @device_id
      @advertising=false
    end

    def inspect
      "<BlueZAdvertiser ad=#{@ad.inspect}>"
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
