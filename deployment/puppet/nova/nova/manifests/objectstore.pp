class nova::objectstore( $enabled=false ) inherits nova {

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  package { "nova-objectstore":
    ensure => present,
    require => Package["python-greenlet"]
  }

  service { "nova-objectstore":
    ensure => $service_ensure,
    enable => $enabled,
    require => Package["nova-objectstore"],
    subscribe => File["/etc/nova/nova.conf"]
  }
}
