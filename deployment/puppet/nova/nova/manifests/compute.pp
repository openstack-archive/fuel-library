# this class should probably never be declared except
# from the virtualization implementation of the compute node
class nova::compute( 
  $enabled = false
#  $type,
#  $hash,
) {

#  if $type == 'xenserver' { 
#    class { 'nova::compute::xenserver':
#      xenapi_connection_url => $hash['xen_connection_url'],
#  $xenapi_connection_url,
#  $xenapi_connection_username,
#  $xenapi_connection_password,
#  $xenapi_inject_image=false,
#    }
#  }
  
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
