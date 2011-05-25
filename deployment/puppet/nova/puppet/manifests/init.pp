class puppet {
  user { 'puppet': 
    ensure => present,
    shell => '/usr/sbin/nologin',
  }
}
