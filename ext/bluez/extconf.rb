# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

# Give it a name
extension_name = 'scan_beacon/bluez'

# The destination
dir_config(extension_name)

if RUBY_PLATFORM =~ /linux/
  abort 'could not find bluetooth library (libbluetooth-dev)' unless have_library("bluetooth")
end

create_makefile(extension_name)
