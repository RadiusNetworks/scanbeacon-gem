module ScanBeacon
  class BLE112Scanner < GenericScanner

    def initialize(opts = {})
      super
      @device = BLE112Device.new opts[:port]
    end

    def each_advertisement
      @device.open do |device|
        device.start_scan
        begin
          keep_scanning = true
          while keep_scanning do
            response = device.read
            if response.advertisement?
              if response.manufacturer_ad?
                keep_scanning = false if yield(response.advertisement_data, response.mac, response.rssi) == false
              else
                keep_scanning = false if yield(response.advertisement_data[4..-1], response.mac, response.rssi, 0x03) == false
              end
            end
          end
        ensure
          device.stop_scan
        end
      end
    end

  end
end
