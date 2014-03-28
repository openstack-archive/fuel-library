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
  Package<| title == $::ceilometer::params::alarm_package or
    title == 'ceilometer-common'|> ~>
  Service<| title == 'ceilometer-alarm-notifier'|>
  if !defined(Service['ceilometer-alarm-notifier']) {
    notify{ "Module ${module_name} cannot notify service ceilometer-alarm-notifier\
 on packages update": }
  }
}
