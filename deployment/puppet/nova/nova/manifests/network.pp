class nova::network( $isServiceEnabled=false ) inherits nova {
  package { "nova-network":
    ensure => present,
    require => Package["python-greenlet"]
  }

  service { "nova-network":
    ensure => $isServiceEnabled,
    require => Package["nova-network"],
    subscribe => File["/etc/nova/nova.conf"]
  }
}
