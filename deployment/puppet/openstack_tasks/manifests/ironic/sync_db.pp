class openstack_tasks::ironic::sync_db {
  notice('MODULAR: ironic/sync_db.pp')

  include ironic::db::sync

  exec { '/bin/true': }
  Exec['/bin/true'] ~> Exec['ironic-dbsync']
}
