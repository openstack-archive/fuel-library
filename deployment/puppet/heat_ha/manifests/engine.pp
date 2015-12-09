class heat_ha::engine inherits heat::engine {
  include heat::params

  $primitive_type  = 'heat-engine'

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
      'timeout' => '60',
    },
    'stop'     => {
      'timeout' => '60',
    },
  }

  $ms_metadata = {
    'interleave' => true,
  }

  pacemaker_wrappers::service { $::heat::params::engine_service_name :
    primitive_type      => $primitive_type,
    metadata            => $metadata,
    complex_type        => 'clone',
    ms_metadata         => $ms_metadata,
    operations          => $operations,
    #    ocf_script_template => $ocf_script_template,
  }

}
