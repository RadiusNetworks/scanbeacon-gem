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
              keep_scanning = false if yield(response.advertisement_data, response.mac, response.rssi) == false
            end
          end
        ensure
          device.stop_scan
        end
      end
    end

  end
end
