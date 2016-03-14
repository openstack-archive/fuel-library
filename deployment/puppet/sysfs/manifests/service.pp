# == Class: sysfs::service
#
# This class actually enables and runs the sysfsutils service to
# apply any configuration found in the config files
#
class sysfs::service inherits sysfs::params {
  service { 'sysfsutils' :
    ensure     => 'running',
    enable     => true,
    status     => '/bin/true',
    hasrestart => true,
  }

  Sysfs_config_value <||> ~> Service['sysfsutils']
}
