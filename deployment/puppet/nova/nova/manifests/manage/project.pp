define nova::manage::project ( $owner ) {
  nova_project { $name:
    ensure => present,
    owner => $owner,
    provider => 'nova_manage',
    notify => Exec["nova-db-sync"],
    require => [Class["nova::db"], Nova::Manage::Admin[$owner]],
  }
}
