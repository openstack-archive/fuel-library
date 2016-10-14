class openstack_tasks::heat::sync_db {
  notice('MODULAR: heat/sync_db.pp')

  include heat::db::sync

  exec { '/bin/true': }
  Exec['/bin/true'] ~> Exec['heat-dbsync']
}
