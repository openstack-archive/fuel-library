class nova::scheduler( $enabled = false) {

  include nova::params

  Exec['post-nova_config'] ~> Service['nova-scheduler']
  Exec['nova-db-sync'] -> Service['nova-scheduler']

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  if($::nova::params::scheduler_package_name != undef) {
    package { 'nova-scheduler':
      name   => $::nova::params::scheduler_package_name,
      ensure => present,
      notify => Service['nova-scheduler'],
    }
  }

  service { "nova-scheduler":
    name => $::nova::params::scheduler_service_name,
    ensure  => $service_ensure,
    enable  => $enabled,
    require => Package[$::nova::params::common_package_name],
    #subscribe => File["/etc/nova/nova.conf"]
  }
}
