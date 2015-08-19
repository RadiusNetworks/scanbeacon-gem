module ScanBeacon
  class BlueZScanner < GenericScanner

    def initialize(opts = {})
      super
      @device_id = opts[:device_id] || BlueZ.devices[0][:device_id]
      BlueZ.device_up @device_id
    end

    def each_advertisement
      ScanBeacon::BlueZ.scan(@device_id) do |mac, ad_data, rssi|
        if ad_data.nil?
          yield(nil)
        elsif ad_data.size > 4
          ad_type = ad_data[4].unpack("C")[0]
          if ad_type == 0xff
            yield(ad_data[5..-1], mac, rssi, ad_type)
          else
            yield(ad_data[9..-1], mac, rssi, ad_type)
          end
        end
      end
    end

  end
end
