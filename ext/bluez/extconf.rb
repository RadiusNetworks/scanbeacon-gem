# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

# Give it a name
extension_name = 'bluez'

# The destination
dir_config(extension_name)

abort 'could not find bluetooth library (libbluetooth-dev)' unless have_library("bluetooth")

create_makefile(extension_name)
