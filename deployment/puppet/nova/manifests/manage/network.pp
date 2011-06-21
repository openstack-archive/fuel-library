define nova::manage::network ( $network, $available_ips ) {
  File['/etc/nova/nova.conf']->Nova_network[$name]
  nova_network { $name:
    ensure        => present,
    network       => $network,
    available_ips => $available_ips,
    provider      => 'nova_manage',
    notify        => Exec["nova-db-sync"],
    require       => Class["nova::db"],
  }
}
