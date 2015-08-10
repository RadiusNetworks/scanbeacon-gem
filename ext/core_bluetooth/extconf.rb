# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

# Give it a name
extension_name = 'core_bluetooth'

# The destination
dir_config(extension_name)

$DLDFLAGS << " -framework Foundation"
$DLDFLAGS << " -framework CoreBluetooth"

unless RUBY_PLATFORM =~ /darwin/
  # don't compile the code on non-mac platforms because
  # CoreBluetooth wont be there, and we may not even have
  # the ability to compile ObjC code.
  COMPILE_C = "echo"
  # create a dummy .so file so RubyGems thinks everything
  # was successful.  We wont try to load it anyway.
  LINK_SO = "touch $@"
end

create_makefile(extension_name)
