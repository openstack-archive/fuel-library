class heat_ha::engine inherits heat::engine {
  $primitive_type  = 'heat-engine'

  if $::osfamily == 'RedHat' {
    $ocf_script_template = 'heat/heat_engine_centos.ocf.erb'
  } else {
    $ocf_script_template = 'heat/heat_engine_ubuntu.ocf.erb'
  }

  $metadata = {
    'resource-stickiness' => '1'
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

  $multistate_hash = {
    'type' => 'clone',
  }

  $ms_metadata = {
    'interleave' => true,
  }

  pacemaker_wrappers::service { $service_name :
    primitive_type      => $primitive_type,
    metadata            => $metadata,
    multistate_hash     => $multistate_hash,
    ms_metadata         => $ms_metadata,
    operations          => $operations,
    ocf_script_template => $ocf_script_template,
  }

}