# == Class: cluster::ceilometer::central
#
# This class is used to configure pacemaker service for ceilometer agent central
#
class cluster::ceilometer_central (
) {
  include ceilometer::agent::central

  pacemaker::new::wrapper { $::ceilometer::params::agent_central_service_name :
    primitive_type     => 'ceilometer-agent-central',
    primitive_provider => 'fuel',
    metadata           => { 'resource-stickiness' => '1' },
    parameters         => { 'user' => 'ceilometer' },
    operations         => {
      'monitor' => {
        'interval' => '20',
        'timeout'  => '30',
      },
      'start'   => {
        'interval' => '0',
        'timeout'  => '360',
      },
      'stop'    => {
        'interval' => '0',
        'timeout'  => '360',
      },
    },
  }
}
