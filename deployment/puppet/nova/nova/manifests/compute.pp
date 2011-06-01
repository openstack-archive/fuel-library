# this class should probably never be declared except
# from the virtualization implementation of the compute node
class nova::compute( 
  $host,
  $compute_type = 'xenserver',
  $xenapi_connection_url,
  $xenapi_connection_username,
  $xenapi_connection_password,
  $xenapi_inject_image=false,
  $enabled = false
) {

  if $compute_type == 'xenserver' { 
    class { 'nova::compute::xenserver':
      xenapi_connection_url => $xenapi_connection_url,
      xenapi_connection_username => $xenapi_connection_username,
      xenapi_connection_password => $xenapi_connection_password,
      xenapi_inject_image => $xenapi_inject_image,
      host => $host,
    }
  } else {
    fail("Unsupported compute type: ${compute_type}")
  }
  
  Nova_config<| |>~>Service['nova-compute']

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  package { "nova-compute":
    ensure => present,
    require => Class['nova']
  }

  service { "nova-compute":
    ensure => $service_ensure,
    enable => $enabled,
    require => Package["nova-compute"],
  }
}
