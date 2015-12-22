# == Class: sysfs
#
# This module manages Linux sysfs values using sysfsutils init script which
# can take values stored in /etc/sysfs.conf and /etc/sysfs.d/*.conf snipplets.
#

class sysfs {
  class { 'sysfs::install' :}->
  class { 'sysfs::service' :}
}
