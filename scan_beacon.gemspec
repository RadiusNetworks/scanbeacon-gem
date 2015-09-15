# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'scan_beacon/version'

Gem::Specification.new do |spec|
  spec.name          = "scan_beacon"
  spec.version       = ScanBeacon::VERSION
  spec.authors       = ["Radius Networks"]
  spec.email         = ["support@radiusnetworks.com"]

  spec.summary       = %q{Provides Beacon scanning functionality}
  spec.homepage      = "https://github.com/RadiusNetworks/scanbeacon-gem"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.extensions    = %w[ext/core_bluetooth/extconf.rb ext/bluez/extconf.rb]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.2"
  spec.add_development_dependency "rake-compiler"
end
