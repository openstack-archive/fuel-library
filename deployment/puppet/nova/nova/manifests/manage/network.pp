define nova::manage::network ( $network, $available_ips ) {
  nova_network { $name:
    ensure        => present,
    network       => $network,
    available_ips => $available_ips,
    provider      => 'nova_manage',
    notify        => Exec["nova-db-sync"],
    require       => Class["nova::db"],
  }
}
