require "scan_beacon/version"
require "scan_beacon/beacon"
require "scan_beacon/eddystone_url_beacon"
require "scan_beacon/beacon/field"
require "scan_beacon/beacon_parser"
require "scan_beacon/generic_scanner"
require "scan_beacon/ble112_device"
require "scan_beacon/ble112_scanner"
require "scan_beacon/generic_advertiser"
require "scan_beacon/generic_individual_advertiser"
require "scan_beacon/ble112_advertiser"
case RUBY_PLATFORM
when /darwin/
  require "scan_beacon/core_bluetooth"
  require "scan_beacon/core_bluetooth_scanner"
when /linux/
  require "scan_beacon/bluez"
  require "scan_beacon/bluez_scanner"
  require "scan_beacon/bluez_advertiser"
end

module ScanBeacon
end
