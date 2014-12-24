if ($osfamily == 'RedHat') {
  package { 'irqbalance' :
    ensure => 'present',
  }

  service { 'irqbalance' :
    ensure => 'running',
    enable => 'true',
  }

  Package['irqbalance'] ~> Service['irqbalance']
}
