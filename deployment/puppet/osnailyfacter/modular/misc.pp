if ($osfamily == 'RedHat') {
  package { 'irqbalance' :
    ensure => 'present',
  }
  ->
  service { 'irqbalance' :
    ensure => 'running',
  }
}
