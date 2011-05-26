class nova::compute( $isServiceEnabled=false )  inherits nova {

  package { "nova-compute":
    ensure => present,
    require => Package["python-greenlet"]
  }

  service { "nova-compute":
    ensure => $isServiceEnabled,
    require => Package["nova-compute"],
    subscribe => File["/etc/nova/nova.conf"]
  }
}
