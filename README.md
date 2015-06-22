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
scanner.scan do |beacons|
  beacons.each do |beacon|
    puts beacon.inspect
  end
end
```

## Set a specific scan cycle period
``` ruby
require 'scan_beacon'
scanner = ScanBeacon::BLE112Scanner.new cycle_seconds: 2
scanner.scan do |beacons|
  beacons.each do |beacon|
    puts beacon.inspect
  end
end
```

# Dependencies
You must have a BLE112 device plugged in to a USB port.
