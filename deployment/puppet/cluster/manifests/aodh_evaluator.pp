#
# Configure aodh-evaluator service in pacemaker/corosync
#
# == Parameters
#
# None.
#
class cluster::aodh_evaluator {
  include ::aodh::params

  $service_name = $::aodh::params::evaluator_service_name

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

  $primitive_type = 'aodh-evaluator'
  $parameters = { 'user' => 'aodh' }

  pacemaker::service { $service_name :
    primitive_type     => $primitive_type,
    metadata           => $metadata,
    parameters         => $parameters,
    operations         => $operations
  }

  Pcmk_resource["p_${service_name}"] ->
  Service[$service_name]
}
