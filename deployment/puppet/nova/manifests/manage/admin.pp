define nova::manage::admin {
  nova_admin{ $name:
    ensure => present,
    provider => 'nova_manage',
    notify => Exec["nova-db-sync"],
    require => Class["nova::db"],
  }
}
