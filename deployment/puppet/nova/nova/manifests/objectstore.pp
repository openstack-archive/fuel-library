class nova::objectstore( $isServiceEnabled=false ) inherits nova {
  package { "nova-objectstore":
    ensure => present,
    require => Package["python-greenlet"]
  }

  service { "nova-objectstore":
    ensure => $isServiceEnabled,
    require => Package["nova-objectstore"],
    subscribe => File["/etc/nova/nova.conf"]
  }
}
