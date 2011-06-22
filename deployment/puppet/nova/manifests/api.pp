class nova::api($enabled=false) {

  Exec['post-nova_config'] ~> Service['nova-api']

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  exec { "initial-db-sync":
    command     => "/usr/bin/nova-manage db sync",
    refreshonly => true,
    require     => [Package["nova-common"], Nova_config['sql_connection']]
  }

  package { "nova-api":
    ensure  => present,
    require => Package["python-greenlet"],
  }
  service { "nova-api":
    ensure  => $service_ensure,
    enable  => $enabled,
    require => Package["nova-api"],
    #subscribe => File["/etc/nova/nova.conf"]
  }
}
