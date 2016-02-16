class ceilometer_ha::alarm::evaluator inherits ceilometer::alarm::evaluator {
  pacemaker_wrappers::service { $::ceilometer::params::alarm_evaluator_service_name :
    primitive_type  => 'ceilometer-alarm-evaluator',
    metadata        => { 'resource-stickiness' => '1' },
    parameters      => { 'user' => 'ceilometer' },
    operations      => {
      'monitor' => {
        'interval' => '20',
        'timeout' => '30',
      },
      'start' => {
        'interval' => '0',
        'timeout'  => '360',
      },
      'stop' => {
        'interval' => '0',
        'timeout'  => '360',
      },
    },
  }
}

