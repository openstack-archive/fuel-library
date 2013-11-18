class ceilometer::alarm::evaluator (
  $enabled = true,
)
 {
  include ceilometer::params

  Ceilometer_config<||> ~> Service['service-alarm-evaluator']
  Package[$::ceilometer::params::alarm_evaluator_package] -> Service['service-alarm-evaluator']

  if ! defined(Package[$::ceilometer::params::alarm_evaluator_package]) {
     package { $::ceilometer::params::alarm_evaluator_package:
     ensure => installed,
     }
  }

  if $enabled {
    $service_ensure = 'running'
  }
  else {
    $service_ensure = 'stopped'
  }

  service { 'service-alarm-evaluator':
    ensure     => $service_ensure,
    name       => $::ceilometer::params::alarm_evaluator_service,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
  }
}
