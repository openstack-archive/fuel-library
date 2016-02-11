class aodh_ha::alarm::evaluator inherits aodh::evaluator {
  pacemaker_wrappers::service { $::aodh::params::evaluator_service_name :
    primitive_type  => 'aodh-evaluator',
    metadata        => { 'resource-stickiness' => '1' },
    parameters      => { 'user' => 'aodh' },
    operations      => {
      'monitor' => {
        'interval' => '20',
        'timeout' => '30',
      },
      'start' => {
        'timeout' => '360',
      },
      'stop' => {
        'timeout' => '360',
      },
    },
    #        ocf_script_file => 'cluster/ocf/aodh-evaluator',
  }
}
