include nova::params

service { $compute_service_name:
  ensure => running,
  enable => true,
}
