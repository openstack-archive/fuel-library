class nova::compute( 
  $enabled = false,
  $nova_config = '/etc/nova/nova.conf',
  $host,
  $connection_type,
  # There will need to be a map of host compute vm to host instance
  $xenapi_connection_url,
  $xenapi_connection_username,
  $xenapi_connection_password,
  $xenapi_inject_image
) {
  
  Nova_config<| |>~>Service['nova_compute']

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
