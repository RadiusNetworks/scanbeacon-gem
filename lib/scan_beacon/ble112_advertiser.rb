module ScanBeacon
  class BLE112Advertiser < GenericIndividualAdvertiser

    def initialize(opts = {})
      super()
      @device = BLE112Device.new opts[:port]
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
