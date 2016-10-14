class openstack_tasks::murano::sync_db {
  notice('MODULAR: murano/sync_db.pp')

  include murano::db::sync

  exec { '/bin/true': }
  Exec['/bin/true'] ~> Exec['murano-dbmanage']
}
