require "scan_beacon/version"
require "scan_beacon/beacon"
require "scan_beacon/beacon_parser"
require "scan_beacon/generic_scanner"
require "scan_beacon/ble112_device"
require "scan_beacon/ble112_scanner"
if RUBY_PLATFORM =~ /darwin/
  require "scan_beacon/core_bluetooth"
  require "scan_beacon/core_bluetooth_scanner"
end

module ScanBeacon
end
