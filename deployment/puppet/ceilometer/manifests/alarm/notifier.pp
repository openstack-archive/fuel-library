# Installs/configures the ceilometer alarm notifier service
#
# == Parameters
#  [*enabled*]
#    Should the service be enabled. Optional. Defauls to true
#
class ceilometer::alarm::notifier (
  $enabled = true,
)
{
  include ceilometer::params

  Ceilometer_config<||> ~> Service['ceilometer-alarm-notifier']
  Package['ceilometer-common'] -> Service['ceilometer-alarm-notifier']
  Package[$::ceilometer::params::alarm_package] -> Service['ceilometer-alarm-notifier']

  if ! defined(Notify['ceilometer-alarm']) {
    package { $::ceilometer::params::alarm_package:
      ensure => installed
    }
    notify { 'ceilometer-alarm': }
  }

  if $enabled {
    $service_ensure = 'running'
  }
  else {
    $service_ensure = 'stopped'
  }

  service { 'ceilometer-alarm-notifier':
    ensure     => $service_ensure,
    name       => $::ceilometer::params::alarm_notifier_service,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
  }
}
