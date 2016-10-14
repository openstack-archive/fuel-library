class openstack_tasks::glance::sync_db {
  notice('MODULAR: glance/sync_db.pp')

  include glance::db::sync

  exec { '/bin/true': }
  Exec['/bin/true'] ~> Exec['glance-manage db_sync']

}


