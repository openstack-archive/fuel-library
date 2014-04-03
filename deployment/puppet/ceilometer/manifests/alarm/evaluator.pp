# Installs/configures the ceilometer alarm evaluator service
#
# == Parameters
#  [*enabled*]
#    Should the service be enabled. Optional. Defauls to true
#
#  [*eval_interval*]
#    Period of evaluation cycle. This should be >= than configured pipeline
#    interval of metrics.
#
#  [*ha_mode*]
#    Should we deploy service in HA mode. Active/Passive mode under pacemaker.
#    Optional. Defauls to false
#
class ceilometer::alarm::evaluator (
  $enabled       = true,
  $eval_interval = 600,
  $ha_mode       = false,
)
{
  include ceilometer::params

  Ceilometer_config<||> ~> Service['ceilometer-alarm-evaluator']
  Package['ceilometer-common'] -> Service['ceilometer-alarm-evaluator']
  Package[$::ceilometer::params::alarm_package] -> Service['ceilometer-alarm-evaluator']

  if ! defined(Notify['ceilometer-alarm']) {
    package { $::ceilometer::params::alarm_package:
      ensure => installed
    }
    notify { 'ceilometer-alarm': }
  }

  tweaks::ubuntu_service_override { 'ceilometer-alarm-evaluator' :
    package_name => 'ceilometer-alarm',
  }

  if $enabled {
    $service_ensure = 'running'
  }
  else {
    $service_ensure = 'stopped'
  }

  ceilometer_config {
    'alarm/evaluation_interval': value => $eval_interval;
  }

  if $ha_mode {

    $res_name = "p_${::ceilometer::params::alarm_evaluator_service}"
    $cib_name = "${::ceilometer::params::alarm_evaluator_service}"

    Package['pacemaker'] -> File['ceilometer-alarm-evaluator-ocf']
    file {'ceilometer-alarm-evaluator-ocf':
      path   =>'/usr/lib/ocf/resource.d/mirantis/ceilometer-alarm-evaluator',
      mode   => '0755',
      owner  => root,
      group  => root,
      source => 'puppet:///modules/ceilometer/ocf/ceilometer-alarm-evaluator',
    }

    File['ceilometer-alarm-evaluator-ocf'] -> Cs_resource[$res_name]
    cs_resource { $res_name:
      ensure          => present,
      cib             => $cib_name,
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

    cs_shadow { $res_name: cib => $cib_name }
    cs_commit { $res_name: cib => $cib_name }

    service { 'ceilometer-alarm-evaluator':
      ensure     => $service_ensure,
      name       => $res_name,
      enable     => $enabled,
      hasstatus  => true,
      hasrestart => true,
      provider   => "pacemaker",
    }

    Cs_shadow[$res_name] ->
      Cs_resource[$res_name] ->
        Cs_commit[$res_name] ->
          Service['ceilometer-alarm-evaluator']

  } else {

    service { 'ceilometer-alarm-evaluator':
      ensure     => $service_ensure,
      name       => $::ceilometer::params::alarm_evaluator_service,
      enable     => $enabled,
      hasstatus  => true,
      hasrestart => true,
    }

  }
  Package<| title == $::ceilometer::params::alarm_package or
    title == 'ceilometer-common'|> ~>
  Service<| title == 'ceilometer-alarm-evaluator'|>
  if !defined(Service['ceilometer-alarm-evaluator']) {
    notify{ "Module ${module_name} cannot notify service ceilometer-alarm-evaluator\
 on packages update": }
  }
}
