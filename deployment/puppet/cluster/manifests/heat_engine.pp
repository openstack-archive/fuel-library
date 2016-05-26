#
# Configure heat-engine in pacemaker/corosync
#
# == Parameters
#
# None.
#
# === Notes
#
# This class requires that ::heat::engine be included in the catalog prior to
# the inclusion of this class.
#
class cluster::heat_engine inherits ::heat::params {
  $primitive_type = 'heat-engine'
  $primitive_provider = 'fuel'

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

  $ms_metadata = {
    'interleave' => true,
  }

  pacemaker::new::wrapper { $engine_service_name :
    primitive_type     => $primitive_type,
    primitive_provider => $primitive_provider,
    metadata           => $metadata,
    complex_type       => 'clone',
    complex_metadata   => $ms_metadata,
    operations         => $operations,
  }

}
