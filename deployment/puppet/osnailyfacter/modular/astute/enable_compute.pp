include nova::params

$compute_service_name = $::nova::params::compute_service_name

service { $compute_service_name:
  ensure     => running,
  enable     => true,
  hasstatus  => true,
  hasrestart => true,
}
