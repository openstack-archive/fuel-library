class openstack_tasks::aodh::sync_db {
  notice('MODULAR: aodh/sync_db.pp')

  include aodh::db::sync

  exec { '/bin/true': }
  Exec['/bin/true'] ~> Exec['aodh-db-sync']
}
