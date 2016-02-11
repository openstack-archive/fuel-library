#
# Configure aodh-evaluator service in pacemaker/corosync
#
# == Parameters
#
# None.
#
class cluster::aodh_evaluator {
  include ::aodh::params

  # migration-threshold is number of tries to
  # start resource on each controller node
  $metadata = {
    'resource-stickiness' => '1',
    'migration-threshold' => '3'
  }

  $operations = {
    'monitor'  => {
      'interval' => '20',
      'timeout'  => '30',
    },
    'start'    => {
      'interval' => '0',
      'timeout'  => '60',
    },
    'stop'     => {
      'interval' => '0',
      'timeout'  => '60',
    },
  }

  pacemaker_wrappers::service { $::aodh::params::evaluator_service_name:
    primitive_type => 'aodh-evaluator',
    metadata       => $metadata,
    parameters     => { 'user' => 'aodh' },
    operations     => $operations,
  }

}
