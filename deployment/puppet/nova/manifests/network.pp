class nova::network( $enabled=false ) {

  Exec['post-nova_config'] ~> Service['nova-network']
  Exec['nova-db-sync'] ~> Service['nova-network']

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  if($::nova::params::network_package_name != undef) {
    package { 'nova-network':
      name   => $::nova::params::network_package_name,
      ensure => present,
      notify => Service['nova-network'],
    }
  }

  service { "nova-network":
    name => $::nova::params::network_service_name,
    ensure  => $service_ensure,
    enable  => $enabled,
    require => Package[$::nova::params::common_package_name],
    before  => Exec['networking-refresh'],
    #subscribe => File["/etc/nova/nova.conf"]
  }
}
