# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

# Give it a name
extension_name = 'scan_beacon/core_bluetooth'

# The destination
dir_config(extension_name)

if RUBY_PLATFORM =~ /darwin/
  $DLDFLAGS << " -framework Foundation"
  $DLDFLAGS << " -framework CoreBluetooth"
  $DLDFLAGS << " -framework IOBluetooth"
else
  # don't compile the code on non-mac platforms because
  # CoreBluetooth wont be there, and we may not even have
  # the ability to compile ObjC code.
  COMPILE_C = "echo"
  CONFIG['CC'] = "echo" # this is for Ruby 2.x mkmf
  # create a dummy .so file so RubyGems thinks everything
  # was successful.  We wont try to load it anyway.
  LINK_SO = "touch $@"
  CONFIG['LDSHARED'] = "touch $@; echo" # for Ruby 2.x mkmf
end

create_makefile(extension_name)
