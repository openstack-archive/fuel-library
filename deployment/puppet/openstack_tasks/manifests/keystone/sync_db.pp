class openstack_tasks::keystone::sync_db {
  notice('MODULAR: keystone/sync_db.pp')

  include keystone::db::sync

  exec { '/bin/true': }
  Exec['/bin/true'] ~> Exec['keystone-manage db_sync']
}
