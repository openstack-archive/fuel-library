define nova::manage::admin {
  File['/etc/nova/nova.conf'] -> Nova::Manage::Admin[$name]
  nova_admin{ $name:
    ensure => present,
    provider => 'nova_manage',
    notify => Exec["nova-db-sync"],
    require => Class["nova::db"],
  }
}
