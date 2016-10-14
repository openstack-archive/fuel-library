class openstack_tasks::openstack_cinder::sync_db {
  notice('MODULAR: openstack_cinder/sync_db')

  include cinder::db::sync

  exec { '/bin/true': }
  Exec['/bin/true'] ~> Exec['cinder-manage db_sync']
}
