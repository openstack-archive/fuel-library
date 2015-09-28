class cluster::heat_ocf inherits heat::engine {
  include heat::params

  $primitive_type  = 'heat-engine'

  #  if $::osfamily == 'RedHat' {
  #  $ocf_script_template = 'heat/heat_engine_centos.ocf.erb'
  #} else {
  #  $ocf_script_template = 'heat/heat_engine_ubuntu.ocf.erb'
  #}

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

  $complex_metadata = {
    'interleave' => true,
  }

  pacemaker::service { $::heat::params::engine_service_name :
    primitive_type      => $primitive_type,
    metadata            => $metadata,
    complex_type        => 'clone',
    complex_metadata    => $complex_metadata,
    operations          => $operations,
    # ocf_script_template => $ocf_script_template,
  }

}
