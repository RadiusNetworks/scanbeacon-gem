module ScanBeacon
  class BLE112Advertiser < GenericAdvertiser

    def initialize(opts = {})
      super()
      @device = BLE112Device.new opts[:port]
    end

    def update_ad    
      self.ad = @parser.generate_ad(@beacon) if @parser && @beacon
      self.start if @advertising
    end

    def ad=(value)
      @ad = value
    end

    def start(with_rotation = false)
      @device.open do
        @device.start_advertising(@ad, with_rotation)
        @advertising = true
      end
    end

    def stop
      @device.open do
        @device.stop_advertising
        @advertising = false
      end
    end

    def inspect
      "<BLE112Advertiser ad=#{@ad.inspect}>"
    end

    def update_ad
      self.ad = @parser.generate_ad(@beacon) if @parser && @beacon
      self.start if @advertising
    end

    def rotate_addr
      @device.open do
        @device.rotate_addr
      end
    end

    def rotate_addr_and_update_ad
      self.update_ad
      self.start(true)
    end

  end
end
