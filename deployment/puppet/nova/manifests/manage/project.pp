define nova::manage::project ( $owner ) {

  File['/etc/nova/nova.conf'] -> Nova_project[$name]
  Exec<| title == 'initial-db-sync' |> -> Nova_project[$name]

  nova_project { $name:
    ensure   => present,
    owner    => $owner,
    notify   => Exec["nova-db-sync"],
    require  => Nova::Manage::Admin[$owner],
  }
}
