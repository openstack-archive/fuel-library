class ceilometer::alarm::notifier (
  $enabled = true,
)
 {
  include ceilometer::params

  Ceilometer_config<||> ~> Service['service-alarm-notifier']
  Package[$::ceilometer::params::alarm_notifier_package] -> Service['service-alarm-notifier']

  if ! defined(Package[$::ceilometer::params::alarm_notifier_package]) {
    package { $::ceilometer::params::alarm_notifier_package :
    ensure => installed,
    }
  }

  if $enabled {
    $service_ensure = 'running'
  }
  else {
    $service_ensure = 'stopped'
  }

  service { 'service-alarm-notifier':
    ensure     => $service_ensure,
    name       => $::ceilometer::params::alarm_notifier_service,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
  }
}
