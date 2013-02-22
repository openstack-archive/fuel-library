class { 'corosync':
  enable_secauth    => false,
  bind_address      => '0.0.0.0',
  multicast_address => '239.1.1.2',
}
corosync::service { 'pacemaker':
  version => '0',
  notify  => Service['corosync'],
}
