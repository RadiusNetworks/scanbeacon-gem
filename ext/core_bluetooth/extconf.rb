# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

# Give it a name
extension_name = 'core_bluetooth'

# The destination
dir_config(extension_name)

$DLDFLAGS << " -framework Foundation"
$DLDFLAGS << " -framework CoreBluetooth"

# Do the work
create_makefile(extension_name)
