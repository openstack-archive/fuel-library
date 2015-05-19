class sysfs {
  class { 'sysfs::install' :}
  class { 'sysfs::config::rps_cpus' :}
  class { 'sysfs::service' :}

  Class['sysfs::install'] ->
  Class['sysfs::config::rps_cpus'] ->
  Class['sysfs::service']
}
