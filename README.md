# ScanBeacon gem

A ruby gem that allows you to scan for beacon advertisements using a BlueGiga BLE112 device.

# Example Usage

## Install the gem
```
gem install scan_beacon
```

## Start a scan
``` ruby
require 'scan_beacon'
scanner = ScanBeacon::BLE112Scanner.new
scanner.scan do |beacon_advert|
  puts beacon_advert.to_s
end
```

## Filter by UUID
``` ruby
require 'scan_beacon'
scanner = ScanBeacon::BLE112Scanner.new(uuid: "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6")
scanner.scan do |beacon_advert|
  puts beacon_advert.to_s
end
```

# Dependencies
You must have a BLE112 device plugged in to a USB port.
