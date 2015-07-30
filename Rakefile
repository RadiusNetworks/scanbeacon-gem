require "bundler/gem_tasks"
require "rake/extensiontask"

Rake::ExtensionTask.new "core_bluetooth" do |ext|
  ext.lib_dir = "lib/scan_beacon"
end

Rake::ExtensionTask.new "bluez" do |ext|
  ext.lib_dir = "lib/scan_beacon"
end
