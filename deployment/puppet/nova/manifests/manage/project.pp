define nova::manage::project ( $owner ) {
  nova_project { $name:
    ensure   => present,
    provider => 'nova_manage',
    owner    => $owner,
    notify   => Exec["nova-db-sync"],
    require  => [Class["nova::db"], Nova::Manage::Admin[$owner]],
  }
}
