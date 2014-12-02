class sahara_ha::api inherits sahara::api {
  $primitive_type  = $sahara::params::sahara_service_name
  $service_name    = $sahara::params::sahara_service_name
  $ocf_script_file = 'sahara_ha/sahara-api.ocf.sh'

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

  $ms_metadata = {
    'interleave' => true,
  }

  pacemaker_wrappers::service { $service_name :
    primitive_type      => $primitive_type,
    metadata            => $metadata,
    complex_type        => 'clone',
    ms_metadata         => $ms_metadata,
    operations          => $operations,
    ocf_script_template => $ocf_script_template,
  }

}
