define nova::manage::network ( $network ) {

  File['/etc/nova/nova.conf'] -> Nova_network[$name]
  Exec<| title == 'initial-db-sync' |> -> Nova_network[$name]

  nova_network { $name:
    ensure        => present,
    network       => $network,
    notify        => Exec["nova-db-sync"],
  }
}
