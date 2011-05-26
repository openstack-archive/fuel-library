class nova::scheduler( $isServiceEnabled ) inherits nova {
  package { "nova-scheduler":
    ensure => present,
    require => Package["python-greenlet"]
  }

  service { "nova-scheduler":
    ensure => $isServiceEnabled,
    require => Package["nova-scheduler"],
    subscribe => File["/etc/nova/nova.conf"]
  }
}
