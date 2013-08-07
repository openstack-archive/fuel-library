#
# This class is being used to check for compatibility with different operating systems
# If the operating system is not supported, it will fail early
#

class operatingsystem::checksupported (
) {
  case $::operatingsystem {
    centos, redhat, ubuntu : { }
    default                : { fail("Operating system $::operatingsystem is not supported") }
  }

  case $::architecture {
    x86_64, amd64 : { }
    default       : { fail("Architecture $::architecture is not supported. 64-bit architecture is required") }
  }

  notify { 'operatingsystem':
    message => "Detected OS $::operatingsystem, architecture $::architecture"
  }
}
