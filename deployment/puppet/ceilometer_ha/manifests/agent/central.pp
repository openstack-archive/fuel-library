class ceilometer_ha::agent::central inherits ceilometer::agent::central {
  pacemaker_wrappers::service { $::ceilometer::params::agent_central_service_name :
    primitive_type  => 'ceilometer-agent-central',
    metadata        => { 'resource-stickiness' => '1' },
    parameters      => { 'user' => 'ceilometer' },
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
    ocf_script_file => 'cluster/ocf/ceilometer-agent-central',
  }
}