define nova::manage::admin {

  File['/etc/nova/nova.conf'] -> Nova_admin[$name]
  Exec<| title == 'initial-db-sync' |> -> Nova_admin[$name]

  nova_admin{ $name:
    ensure => present,
    provider => 'nova_manage',
    notify => Exec["nova-db-sync"],
  }
}
