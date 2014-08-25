# Installs the ceilometer alarm evaluator service
#
# == Params
#  [*enabled*]
#    should the service be enabled
#  [*evaluation_interval*]
#    define the time interval for the alarm evaluator
#  [*evaluation_service*]
#    define which service use for the evaluator
#  [*partition_rpc_topic*]
#    define which topic the alarm evaluator should access
#  [*record_history*]
#    Record alarm change events
#
class ceilometer::alarm::evaluator (
  $enabled = true,
  $evaluation_interval = 60,
  $evaluation_service  = 'ceilometer.alarm.service.SingletonAlarmService',
  $partition_rpc_topic = 'alarm_partition_coordination',
  $record_history      = true,
) {

  include ceilometer::params

  validate_re($evaluation_interval,'^(\d+)$')

  Ceilometer_config<||> ~> Service['ceilometer-alarm-evaluator']

  Package[$::ceilometer::params::alarm_package_name] -> Service['ceilometer-alarm-evaluator']
  Package[$::ceilometer::params::alarm_package_name] -> Package<| title == 'ceilometer-alarm' |>
  ensure_packages($::ceilometer::params::alarm_package_name)

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  Package['ceilometer-common'] -> Service['ceilometer-alarm-evaluator']

    $res_name = "p_${::ceilometer::params::alarm_evaluator_service}"

    Package['ceilometer-common'] -> File['ceilometer-alarm-evaluator-ocf']
    Package[$::ceilometer::params::alarm_package] -> File['ceilometer-alarm-evaluator-ocf']
    Package['pacemaker'] -> File['ceilometer-alarm-evaluator-ocf']
    file {'ceilometer-alarm-evaluator-ocf':
      path   =>'/usr/lib/ocf/resource.d/mirantis/ceilometer-alarm-evaluator',
      mode   => '0755',
      owner  => root,
      group  => root,
      source => 'puppet:///modules/ceilometer/ocf/ceilometer-alarm-evaluator',
    }

    if $primary_controller {
      corosync::resource { $res_name:
        ensure          => present,
        primitive_class => 'ocf',
        provided_by     => 'mirantis',
        primitive_type  => 'ceilometer-alarm-evaluator',
        metadata        => { 'target-role' => 'stopped' },
        parameters      => { 'user' => 'ceilometer' },
        operations      => {
          'monitor'  => {
            'interval' => '20',
            'timeout'  => '30'
          }
          ,
          'start'    => {
            'timeout' => '360'
          }
          ,
          'stop'     => {
            'timeout' => '360'
          }
        },
      }
      File['ceilometer-alarm-evaluator-ocf'] -> Cs_resource[$res_name] -> Service['ceilometer-alarm-evaluator']
    } else {
      File['ceilometer-alarm-evaluator-ocf'] -> Service['ceilometer-alarm-evaluator']
    }

    service { 'ceilometer-alarm-evaluator':
      ensure     => $service_ensure,
      name       => $res_name,
      enable     => $enabled,
      hasstatus  => true,
      hasrestart => true,
      provider   => "pacemaker",
    }

  } else {
    Package['ceilometer-common'] -> Service['ceilometer-alarm-evaluator']
    Package[$::ceilometer::params::alarm_package] -> Service['ceilometer-alarm-evaluator']

  ceilometer_config {
    'alarm/evaluation_interval' :  value => $evaluation_interval;
    'alarm/evaluation_service'  :  value => $evaluation_service;
    'alarm/partition_rpc_topic' :  value => $partition_rpc_topic;
    'alarm/record_history'      :  value => $record_history;
    }
}
