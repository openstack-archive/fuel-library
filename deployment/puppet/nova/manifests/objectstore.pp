class nova::objectstore( $enabled=false ) {

  include nova::params

  Exec['post-nova_config'] ~> Service['nova-objectstore']
  Exec['nova-db-sync'] ~> Service['nova-objectstore']

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  service { "nova-objectstore":
    name => $::nova::params::objectstore_service_name,
    ensure  => $service_ensure,
    enable  => $enabled,
    require => Package[$::nova::params::package_names],
    #subscribe => File["/etc/nova/nova.conf"]
  }
}
