module ScanBeacon
  class CoreBluetoothScanner < GenericScanner

    def each_advertisement
      keep_scanning = true
      CoreBluetooth::scan do
        sleep 0.2
        advertisements = CoreBluetooth::new_adverts
        advertisements.each do |scan|
          keep_scanning = false if yield(scan[:data], scan[:device], scan[:rssi]) == false
        end
        if advertisements.empty?
          keep_scanning = false if yield(nil, nil, nil) == false
        end
        keep_scanning
      end
    end

  end
end
