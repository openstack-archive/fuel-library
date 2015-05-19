class sysfs::config::rps_cpus inherits sysfs::params {
  sysfs_config_value { 'rps_cpus' :
    ensure  => 'present',
    name    => "${config_dir}/rps_cpus.conf",
    value   => cpu_affinity_hex($::processorcount),
    sysfs   => '/sys/class/net/*/queues/rx-*/rps_cpus',
    exclude => '/sys/class/net/lo/*',
  }
}
