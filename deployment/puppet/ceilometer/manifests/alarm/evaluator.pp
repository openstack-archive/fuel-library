# Installs the ceilometer alarm evaluator service
#
# == Params
#  [*enabled*]
#    (optional) Should the service be enabled.
#    Defaults to true.
#
#  [*manage_service*]
#    (optional) Whether the service should be managed by Puppet.
#    Defaults to true.
#
#  [*evaluation_interval*]
#    (optional) Define the time interval for the alarm evaluator
#    Defaults to 60.
#
#  [*evaluation_service*]
#    (optional) Define which service use for the evaluator
#    Defaults to 'ceilometer.alarm.service.SingletonAlarmService'.
#
#  [*partition_rpc_topic*]
#    (optional) Define which topic the alarm evaluator should access
#    Defaults to 'alarm_partition_coordination'.
#
#  [*record_history*]
#    (optional) Record alarm change events
#    Defaults to true.
#
#  [*coordination_url*]
#    (optional) The url to use for distributed group membership coordination.
#    Defaults to undef.
#
class ceilometer::alarm::evaluator (
  $manage_service      = true,
  $enabled             = true,
  $evaluation_interval = 60,
  $evaluation_service  = 'ceilometer.alarm.service.SingletonAlarmService',
  $partition_rpc_topic = 'alarm_partition_coordination',
  $record_history      = true,
  $coordination_url    = undef,
) {

  include ::ceilometer::params

  validate_re("${evaluation_interval}",'^(\d+)$')

  Ceilometer_config<||> ~> Service['ceilometer-alarm-evaluator']

  Package[$::ceilometer::params::alarm_package_name] -> Service['ceilometer-alarm-evaluator']
  Package[$::ceilometer::params::alarm_package_name] -> Package<| title == 'ceilometer-alarm' |>
  ensure_packages($::ceilometer::params::alarm_package_name,
    { tag => 'openstack' }
  )

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  Package['ceilometer-common'] -> Service['ceilometer-alarm-evaluator']

  service { 'ceilometer-alarm-evaluator':
    ensure     => $service_ensure,
    name       => $::ceilometer::params::alarm_evaluator_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true
  }

  ceilometer_config {
    'alarm/evaluation_interval' :  value => $evaluation_interval;
    'alarm/evaluation_service'  :  value => $evaluation_service;
    'alarm/partition_rpc_topic' :  value => $partition_rpc_topic;
    'alarm/record_history'      :  value => $record_history;
  }

  if $coordination_url {
    ensure_resource('ceilometer_config', 'coordination/backend_url',
      {'value' => $coordination_url})
  }
}
