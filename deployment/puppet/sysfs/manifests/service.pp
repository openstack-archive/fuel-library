# == Class: sysfs::service
#
# This class actually enables and runs the sysfsutils service to
# apply any configuration found in the config files
#
class sysfs::service inherits sysfs::params {
  service { 'sysfsutils' :
    ensure     => 'running',
    enable     => true,
    hasstatus  => false,
    hasrestart => true,
  }

  tweaks::ubuntu_service_override { 'sysfsutils' :
    package_name => $package,
  }

  Sysfs_config_value <||> ~> Service['sysfsutils']
}
