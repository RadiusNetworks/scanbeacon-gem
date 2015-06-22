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

## Add a custom beacon layout
By default, this gem supports AltBeacon advertisements.  But you can add a beacon parser to support other major beacon formats as well.

Example:
``` ruby
scanner = ScanBeacon::BLE112Scanner.new
scanner.add_parser( ScanBeacon::BeaconParser.new(:mybeacon, "m:2-3=0000,i:4-19,i:20-21,i:22-23,p:24-24") )
...
```

# Dependencies
You must have a BLE112 device plugged in to a USB port.
