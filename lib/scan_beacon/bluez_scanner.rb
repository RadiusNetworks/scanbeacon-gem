require 'timeout'

module ScanBeacon
  class BlueZScanner < GenericScanner

    def each_advertisement
      ScanBeacon::BlueZ.scan do |mac, ad_data, rssi|
        yield(ad_data[5..-1], mac, rssi)
      end
    end

  end
end
