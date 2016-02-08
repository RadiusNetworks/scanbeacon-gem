module ScanBeacon
  class CoreBluetoothScanner < GenericScanner

    def each_advertisement
      keep_scanning = true
      CoreBluetooth::scan do
        sleep 0.2
        advertisements = CoreBluetooth::new_adverts
        advertisements.each do |scan|
          if scan[:service_uuid]
            advert = scan[:service_uuid] + scan[:data]
            keep_scanning = false if yield(advert, scan[:device], scan[:rssi], 0x03) == false
          else
            keep_scanning = false if yield(scan[:data], scan[:device], scan[:rssi], 0xff) == false
          end
        end
        if advertisements.empty?
          keep_scanning = false if yield(nil, nil, nil) == false
        end
        keep_scanning
      end
    end

  end
  DefaultScanner = CoreBluetoothScanner
end
