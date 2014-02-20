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
  Package['ceilometer-alarm'] -> Service['ceilometer-alarm-notifier']

  if ! defined(Package['ceilometer-alarm']) {
    package { 'ceilometer-alarm' :
      ensure => installed,
      name   => $::ceilometer::params::alarm_package,
    }
  }

  tweaks::ubuntu_service_override { 'ceilometer-alarm-notifier' :
    package_name => 'ceilometer-alarm',
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
