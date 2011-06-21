define nova::manage::project ( $owner ) {
  File['/etc/nova/nova.conf'] -> Nova_project[$name]
  nova_project { $name:
    ensure   => present,
    provider => 'nova_manage',
    owner    => $owner,
    notify   => Exec["nova-db-sync"],
    require  => [Class["nova::db"], Nova::Manage::Admin[$owner]],
  }
}
