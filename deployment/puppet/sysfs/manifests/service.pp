class sysfs::service inherits sysfs::params {
  service { 'sysfsutils' :
    ensure     => 'running',
    enable     => true,
    hasstatus  => false,
    hasrestart => true,
  }

  Sysfs_config_value <||> ~> Service['sysfsutils']

  if defined(Class['sysfs::install']) {
    Class['sysfs::install'] ~> Service['sysfsutils']
  }
}
