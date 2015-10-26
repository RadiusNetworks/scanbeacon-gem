module ScanBeacon
  class CoreBluetoothAdvertiser < GenericIndividualAdvertiser

    def initialize(opts = {})
      super
    end

    def ad=(value)
      @ad = value
      CoreBluetooth.set_advertisement_data @ad
    end

    def start
      CoreBluetooth.start_advertising
    end

    def stop
      CoreBluetooth.stop_advertising
    end

    def inspect
      "<CoreBluetoothAdvertiser ad=#{@ad.inspect}>"
    end

  end
end
