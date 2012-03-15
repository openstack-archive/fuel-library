class nova::api($enabled=false) {

  Exec['post-nova_config'] ~> Service['nova-api']
  Exec['nova-db-sync'] ~> Service['nova-api']

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  exec { "initial-db-sync":
    command     => "/usr/bin/nova-manage db sync",
    refreshonly => true,
    require     => [Package[$::nova::params::package_names], Nova_config['sql_connection']],
  }

  service { "nova-api":
    name    => $::nova::params::api_service_name,
    ensure  => $service_ensure,
    enable  => $enabled,
    require => Package[$::nova::params::package_names],
    #subscribe => File["/etc/nova/nova.conf"]
  }
}
